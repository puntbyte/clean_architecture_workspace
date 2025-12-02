// test/src/lints/dependency/enforce_abstract_repository_dependency_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/dependency/enforce_abstract_repository_dependency.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceAbstractRepositoryDependency Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('abstract_repo_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // 1. Define the Port (Interface) in Domain - ALLOWED
      addFile(
        'lib/features/user/domain/ports/user_repository.dart',
        'abstract class UserRepository {}',
      );

      // 2. Define the Repository (Implementation) in Data - FORBIDDEN
      addFile(
        'lib/features/user/data/repositories/user_repository_impl.dart',
        '''
        import '../../domain/ports/user_repository.dart';
        class UserRepositoryImpl implements UserRepository {}
        ''',
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    Future<List<Diagnostic>> runLint({required String filePath}) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      // Use defaults (ports in 'ports', repositories in 'repositories')
      final config = makeConfig();

      final lint = EnforceAbstractRepositoryDependency(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when UseCase depends on Concrete Repository', () async {
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, '''
        import '../../data/repositories/user_repository_impl.dart';
        
        class GetUser {
          // VIOLATION: Depends on Impl (Data Layer)
          final UserRepositoryImpl repo; 
          GetUser(this.repo);
        }
      ''');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('UseCases must depend on repository abstractions'));
      // Smart Correction check
      expect(lints.first.correctionMessage, contains('Depend on the `UserRepository` interface'));
    });

    test('reports violation when UseCase instantiates Concrete Repository locally', () async {
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, '''
        import '../../data/repositories/user_repository_impl.dart';
        
        class GetUser {
          void call() {
            // VIOLATION: Instantiation of concrete class
            final repo = UserRepositoryImpl(); 
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
    });

    test('does not report violation when UseCase depends on Abstract Port', () async {
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, '''
        import '../ports/user_repository.dart';
        
        class GetUser {
          // OK: Depends on Interface (Domain Layer)
          final UserRepository repo; 
          GetUser(this.repo);
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('ignores files that are not UseCases', () async {
      // A DI setup file in the root or core might need to link them together.
      final path = 'lib/injection_container.dart';
      addFile(path, '''
        import 'features/user/data/repositories/user_repository_impl.dart';
        void init() {
          final repo = UserRepositoryImpl(); // OK here
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}