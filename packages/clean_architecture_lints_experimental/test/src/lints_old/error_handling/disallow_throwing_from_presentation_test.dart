// test/src/lints/error_handling/disallow_throwing_from_presentation_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/error_handling'
    '/disallow_throwing_from_presentation.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowThrowingFromPresentation Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('presentation_throw_test_');
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
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      // Configure similar to the user's requested yaml
      final config = makeConfig(
        // Define Types
        typeDefinitions: {
          'exception': {
            'raw': {'name': 'Exception'}, // dart:core Exception
            'custom': {'name': 'MyError', 'import': 'package:test_project/core/error.dart'},
          },
        },
        // Define Rules
        errorHandlers: [
          {
            'on': 'presentation',
            'role': 'consumer',
            'forbidden': [
              {
                'operation': ['throw', 'rethrow'],
                'target_type': 'exception.raw', // Bans throwing Exception
              },
              {
                'operation': ['throw'],
                'target_type': 'exception.custom', // Bans throwing MyError
              },
            ],
          },
        ],
      );

      final lint = DisallowThrowingFromPresentation(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when Widget throws a raw Exception', () async {
      const path = 'lib/features/home/presentation/pages/home_page.dart';
      addFile(path, '''
        import 'package:flutter/material.dart';
        class HomePage {
          void init() {
            throw Exception('Crash'); // VIOLATION
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Presentation layer must not throw'));
    });

    test('reports violation when Manager uses rethrow', () async {
      const path = 'lib/features/home/presentation/managers/home_cubit.dart';
      addFile(path, '''
        class HomeCubit {
          void load() {
            try {
              // ...
            } catch (e) {
              rethrow; // VIOLATION
            }
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
    });

    test('reports violation when Widget throws configured Custom Error', () async {
      addFile('lib/core/error.dart', 'class MyError {}');

      const path = 'lib/features/home/presentation/widgets/my_button.dart';
      addFile(path, '''
        import 'package:test_project/core/error.dart';
        class MyButton {
          void press() {
            throw MyError(); // VIOLATION (Matches exception.custom)
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, hasLength(1));
    });

    test('does NOT report violation if throwing a type NOT in the forbidden list', () async {
      // Our config only banned 'Exception' and 'MyError'.
      // Throwing 'String' or 'Error' (which is distinct from Exception in Dart) should pass.
      const path = 'lib/features/home/presentation/pages/safe_page.dart';
      addFile(path, '''
        class SafePage {
          void crash() {
            throw "String Error"; // OK (Not in forbidden list)
            throw Error();        // OK (Not 'Exception')
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('does NOT report violation if file is NOT in Presentation layer', () async {
      // Data layer might be allowed to throw (depending on other rules, but THIS rule ignores it).
      const path = 'lib/features/home/data/sources/local_source.dart';
      addFile(path, '''
        class LocalSource {
          void fetch() {
            throw Exception('Disk Error'); // OK (Rule applies to Presentation only)
          }
        }
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}
