// test/src/lints/purity/disallow_model_return_from_repository_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/type_safety/disallow_model_return_from_repository.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowModelReturnFromRepository Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('model_return_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // 1. Define core types
      addFile('lib/core/either.dart', '''
        class Either<L, R> {}
        class Left<L, R> implements Either<L, R> { const Left(this.value); final L value; }
        class Right<L, R> implements Either<L, R> { const Right(this.value); final R value; }
      ''');

      // 2. Define Entity
      addFile('lib/features/user/domain/entities/user_entity.dart', 'class UserEntity {}');

      // 3. Define Model
      addFile('lib/features/user/data/models/user_model.dart', '''
        import '../../../domain/entities/user_entity.dart';
        class UserModel extends UserEntity { 
          UserEntity toEntity() => UserEntity(); 
        }
      ''');

      // 4. Define Repository Port (Domain)
      addFile('lib/features/user/domain/ports/user_repository.dart', '''
        import 'package:test_project/core/either.dart';
        import 'package:test_project/features/user/domain/entities/user_entity.dart';
        abstract class UserRepository {
          Future<Either<Exception, UserEntity>> getUser();
        }
      ''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    Future<List<Diagnostic>> runLint(String filePath) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(
        typeSafeties: [
          {
            'on': 'port',
            'returns': {'unsafe_type': 'Future', 'safe_type': 'Either'}
          }
        ],
      );
      final lint = DisallowModelReturnFromRepository(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when repository returns a Model inside an Either', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/core/either.dart';
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        import 'package:test_project/features/user/domain/entities/user_entity.dart';
        import 'package:test_project/features/user/data/models/user_model.dart';
        
        class UserRepositoryImpl implements UserRepository {
          @override
          Future<Either<Exception, UserEntity>> getUser() async {
            final model = UserModel();
            return Right(model); // VIOLATION: returning model wrapped in Right
          }
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Repository methods must return domain Entities'));
    });

    test('reports no violation when repository returns a mapped Entity', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/core/either.dart';
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        import 'package:test_project/features/user/domain/entities/user_entity.dart';
        import 'package:test_project/features/user/data/models/user_model.dart';
        
        class UserRepositoryImpl implements UserRepository {
          @override
          Future<Either<Exception, UserEntity>> getUser() async {
            final model = UserModel();
            return Right(model.toEntity()); // OK
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('ignores returns in private helper methods (not overrides)', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import 'package:test_project/features/user/data/models/user_model.dart';
        class UserRepositoryImpl {
          UserModel _privateHelper() {
            return UserModel();
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}