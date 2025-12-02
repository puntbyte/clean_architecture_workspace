// test/src/lints/dependency/disallow_dependency_instantiation_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/dependency/disallow_dependency_instantiation.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowDependencyInstantiation Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('di_instantiation_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Define Architectural Components
      addFile('lib/features/user/data/sources/user_remote_source.dart', 'class UserRemoteSource {}');
      addFile('lib/features/user/data/models/user_model.dart', 'class UserModel {}');
      addFile('lib/features/user/domain/usecases/get_user.dart', 'class GetUser {}');
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

      final config = makeConfig();
      final lint = DisallowDependencyInstantiation(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when Repository instantiates DataSource in field', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        class UserRepositoryImpl {
          // VIOLATION: Creating a Source (Service component)
          final source = UserRemoteSource(); 
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Do not instantiate architectural dependencies'));
    });

    test('reports violation when Manager instantiates UseCase in constructor initializer', () async {
      final path = 'lib/features/user/presentation/managers/user_bloc.dart';
      addFile(path, '''
        import '../../domain/usecases/get_user.dart';
        class UserBloc {
          final GetUser getUser;
          // VIOLATION: Creating a UseCase (Service component)
          UserBloc() : getUser = GetUser(); 
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('does NOT report violation when Repository instantiates a Model (Data)', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../models/user_model.dart';
        class UserRepositoryImpl {
          // OK: Models are data containers, fine to create.
          final emptyModel = UserModel(); 
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does NOT report violation when instantiating inside a method body', () async {
      // Local variables in methods are not Dependency Injection points.
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        class UserRepositoryImpl {
          void doSomething() {
            final source = UserRemoteSource(); // OK (Local scope)
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('does NOT report violation for external packages (e.g. Map)', () async {
      final path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        class UserRepositoryImpl {
          final cache = Map<String, dynamic>(); // OK (Dart SDK)
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}