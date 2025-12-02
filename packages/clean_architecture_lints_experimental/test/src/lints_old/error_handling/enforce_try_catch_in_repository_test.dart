// test/src/lints/error_handling/enforce_try_catch_in_repository_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/error_handling/'
    'enforce_try_catch_in_repository.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceTryCatchInRepository Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('try_catch_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );

      // DataSource Interface
      addFile(
        'lib/features/user/data/sources/user_remote_source.dart',
        '''
        abstract class UserRemoteSource {
          Future<void> fetchUser();
        }
        ''',
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? errorHandlers,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(errorHandlers: errorHandlers);
      final lint = EnforceTryCatchInRepository(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when DataSource call is not wrapped in try-catch (Default)', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);
          Future<void> getUser() async {
            await source.fetchUser(); // VIOLATION
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Calls to a DataSource must be wrapped'));
    });

    test('reports violation when explicitly enabled via config', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);
          Future<void> getUser() async {
            await source.fetchUser(); // VIOLATION
          }
        }
      ''');

      final lints = await runLint(
        filePath: path,
        errorHandlers: [
          {
            'on': 'repository',
            'role': 'boundary',
            'required': [
              {'operation': 'try_return'},
            ],
          },
        ],
      );
      expect(lints, hasLength(1));
    });

    test('does NOT report violation if try_return is NOT required in config', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);
          Future<void> getUser() async {
            // This would normally be a violation, but we disabled the requirement via config
            await source.fetchUser(); 
          }
        }
      ''');

      final lints = await runLint(
        filePath: path,
        errorHandlers: [
          {
            'on': 'repository',
            'role': 'boundary',
            'required': [], // Empty required list means 'try_return' is not enforced
          },
        ],
      );
      expect(lints, isEmpty);
    });

    test('reports violation in finally block', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);
          Future<void> getUser() async {
            try {} finally {
              await source.fetchUser(); // VIOLATION
            }
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
    });

    test('does not report violation when safe', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        import '../sources/user_remote_source.dart';
        class UserRepositoryImpl {
          final UserRemoteSource source;
          UserRepositoryImpl(this.source);
          Future<void> getUser() async {
            try {
              await source.fetchUser(); // OK
            } catch (e) {}
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}
