// test/src/lints/error_handling/enforce_try_catch_in_repository_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/enforce_try_catch_in_repository.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceTryCatchInRepository Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint(String filePath) async {
      final config = makeConfig();
      final lint = EnforceTryCatchInRepository(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final resolvedUnit =
          await contextCollection
                  .contextFor(p.normalize(filePath))
                  .currentSession
                  .getResolvedUnit(p.normalize(filePath))
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('try_catch_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(testProjectPath, '.dart_tool/package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
        '"packageUri": "lib/"}]}',
      );

      // Define a DataSource interface
      writeFile(
        p.join(testProjectPath, 'lib/features/user/data/sources/user_remote_source.dart'),
        '''
        abstract class UserRemoteSource {
          Future<void> fetchUser();
        }
        ''',
      );

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when DataSource call is not wrapped in try-catch', () async {
      final path = p.join(
        testProjectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        import '../sources/user_remote_source.dart';
        
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);

          Future<void> getUser() async {
            await source.fetchUser(); // VIOLATION
          }
        }
      ''');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_try_catch_in_repository');
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'Calls to a DataSource must be wrapped in a `try` block.',
      );
    });

    test('should report violation when DataSource call is in a finally block', () async {
      // Calling a risky method in finally is bad practice as it's not caught.
      final path = p.join(
        testProjectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        import '../sources/user_remote_source.dart';
        
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);

          Future<void> getUser() async {
            try {
              print('hello');
            } catch(e) {
              // handle
            } finally {
              await source.fetchUser(); // VIOLATION
            }
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('should not report violation when DataSource call is safely wrapped', () async {
      final path = p.join(
        testProjectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        import '../sources/user_remote_source.dart';
        
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);

          Future<void> getUser() async {
            try {
              await source.fetchUser(); // OK
            } catch (e) {
              // convert to Failure
            }
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should not report violation for calls to non-DataSource objects', () async {
      final path = p.join(
        testProjectPath,
        'lib/features/user/data/repositories/user_repository_impl.dart',
      );
      writeFile(path, '''
        class OtherService {
          void doSafeWork() {}
        }
        
        class UserRepositoryImpl {
          final OtherService service;
          UserRepositoryImpl(this.service);

          void work() {
            service.doSafeWork(); // OK, not a data source
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should not run on files that are not repositories', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/usecases/get_user.dart');
      writeFile(path, '''
        import '../../data/sources/user_remote_source.dart';
        class GetUser {
          final UserRemoteSource source;
          GetUser(this.source);
          
          // UseCase calling source directly is bad architecture, but NOT the responsibility of 
          // THIS lint.
          // Other lints (layer independence) handle this. This lint strictly checks repositories.
          Future<void> call() async {
            await source.fetchUser(); 
          }
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}
