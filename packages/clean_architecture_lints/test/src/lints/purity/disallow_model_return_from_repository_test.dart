// test/src/lints/purity/disallow_model_return_from_repository_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/purity/disallow_model_return_from_repository.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowModelReturnFromRepository Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint(String filePath) async {
      final config = makeConfig(
        typeSafeties: [
          {
            'on': 'port', // Updated to 'port'
            'returns': {'unsafe_type': 'Future', 'safe_type': 'Either'}
          }
        ],
      );
      final lint = DisallowModelReturnFromRepository(config: config, layerResolver: LayerResolver(config));

      final resolvedUnit = await contextCollection
          .contextFor(p.normalize(filePath))
          .currentSession
          .getResolvedUnit(p.normalize(filePath)) as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('model_return_test_');
      projectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(projectPath).createSync(recursive: true);

      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(p.join(projectPath, '.dart_tool/package_config.json'),
          '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}');

      // 1. Define Either/Right
      writeFile(p.join(projectPath, 'lib/core/either.dart'), '''
        class Either<L, R> {}
        class Left<L, R> implements Either<L, R> { const Left(this.value); final L value; }
        class Right<L, R> implements Either<L, R> { const Right(this.value); final R value; }
      ''');

      // 2. Define Entity
      writeFile(p.join(projectPath, 'lib/features/user/domain/entities/user_entity.dart'), 'class UserEntity {}');

      // 3. Define Model
      writeFile(p.join(projectPath, 'lib/features/user/data/models/user_model.dart'), '''
        import '../../../domain/entities/user_entity.dart';
        class UserModel extends UserEntity { 
          UserEntity toEntity() => UserEntity(); 
        }
      ''');

      // 4. Define Repository Port (formerly contract)
      // FIX: Path is now `domain/ports/` to match makeConfig defaults
      writeFile(p.join(projectPath, 'lib/features/user/domain/ports/user_repository.dart'), '''
        import 'package:test_project/core/either.dart';
        import 'package:test_project/features/user/domain/entities/user_entity.dart';
        abstract class UserRepository {
          Future<Either<Exception, UserEntity>> getUser();
        }
      ''');

      contextCollection = AnalysisContextCollection(includedPaths: [projectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when repository returns a Model inside an Either', () async {
      final path = p.join(projectPath, 'lib/features/user/data/repositories/user_repository_impl.dart');

      // FIX: Updated import to point to `ports`
      writeFile(path, '''
        import 'package:test_project/core/either.dart';
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        import 'package:test_project/features/user/domain/entities/user_entity.dart';
        import 'package:test_project/features/user/data/models/user_model.dart';
        
        class UserRepositoryImpl implements UserRepository {
          @override
          Future<Either<Exception, UserEntity>> getUser() async {
            final model = UserModel();
            return Right(model); // VIOLATION
          }
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'disallow_model_return_from_repository');
    });

    test('should not report violation when repository correctly returns an Entity', () async {
      final path = p.join(projectPath, 'lib/features/user/data/repositories/user_repository_impl.dart');

      // FIX: Updated import to point to `ports`
      writeFile(path, '''
        import 'package:test_project/core/either.dart';
        import 'package:test_project/features/user/domain/ports/user_repository.dart';
        import 'package:test_project/features/user/domain/entities/user_entity.dart';
        import 'package:test_project/features/user/data/models/user_model.dart';
        
        class UserRepositoryImpl implements UserRepository {
          @override
          Future<Either<Exception, UserEntity>> getUser() async {
            final model = UserModel();
            return Right(model.toEntity()); 
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should not report violation for returns in private helper methods', () async {
      final path = p.join(projectPath, 'lib/features/user/data/repositories/user_repository_impl.dart');
      writeFile(path, '''
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
