// test/src/lints/error_handling/disallow_throwing_from_repository_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/error_handling'
    '/disallow_throwing_from_repository.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowThrowingFromRepository Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('throwing_repo_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
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
      final lint = DisallowThrowingFromRepository(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation for `throw` when default strict mode is active', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        class UserRepositoryImpl {
          void doSomething() {
            throw Exception('Failed'); // VIOLATION
          }
        }
      ''');

      // No config passed -> Default behavior (Strict)
      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Repositories should not throw or rethrow'));
    });

    test('reports violation for `rethrow` when default strict mode is active', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        class UserRepositoryImpl {
          void doSomething() {
            try {
            } catch (e) {
              rethrow; // VIOLATION (Strict Boundary)
            }
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
    });

    test('reports violation based on explicit configuration', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        class UserRepositoryImpl {
          void doSomething() {
            throw Exception('e'); // Should trigger
            try {} catch(e) { rethrow; } // Should trigger
          }
        }
      ''');

      // Explicitly forbid both
      final lints = await runLint(
        filePath: path,
        errorHandlers: [
          {
            'on': 'repository',
            'role': 'boundary',
            'forbidden': [
              {
                'operation': ['throw', 'rethrow'],
              },
            ],
          },
        ],
      );

      expect(lints, hasLength(2));
    });

    test('does NOT report violation if operation is not forbidden in config', () async {
      const path = 'lib/features/user/data/repositories/user_repository_impl.dart';
      addFile(path, '''
        class UserRepositoryImpl {
          void doSomething() {
            // Throw is NOT forbidden in this config
            throw Exception('Allowed'); 
          }
        }
      ''');

      // Config that only forbids 'rethrow', effectively allowing 'throw'
      final lints = await runLint(
        filePath: path,
        errorHandlers: [
          {
            'on': 'repository',
            'role': 'boundary',
            'forbidden': [
              {'operation': 'rethrow'},
            ],
          },
        ],
      );

      expect(lints, isEmpty);
    });

    test('ignores files that are not repositories', () async {
      const path = 'lib/features/user/data/sources/user_remote_source.dart';
      addFile(path, '''
        class UserRemoteSource {
          void fetch() {
            throw Exception('Network Error'); // OK in Source
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}
