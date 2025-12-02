import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/type_safety/enforce_type_safety.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('EnforceTypeSafety Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('type_safety_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');
      addFile('.dart_tool/package_config.json', '{"configVersion": 2, "packages": []}');

      addFile('lib/core/utils/types.dart', '''
        class FutureEither<L, R> {}
        class IntId {}
        class StringId {}
      ''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> typeSafeties,
      Map<String, dynamic>? typeDefinitions,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(
        typeSafeties: typeSafeties,
        typeDefinitions: typeDefinitions,
      );
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('should report violation when return type matches Forbidden list (raw Future)', () async {
      const path = 'lib/features/auth/domain/ports/auth_port.dart';
      addFile(path, '''
        import 'dart:async';
        abstract interface class AuthPort {
          // VIOLATION: Forbidden 'Future'
          Future<void> login(); 
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeSafeties: [
          {
            'on': ['port'],
            'forbidden': [
              {'kind': 'return', 'type': 'Future'},
            ],
            'allowed': [
              {'kind': 'return', 'type': 'FutureEither'},
            ], // For suggestion
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Use `FutureEither` instead of `Future`'));
    });

    test(
      'should report violation when return type does NOT match Allowed list (Whitelist mode)',
      () async {
        const path = 'lib/features/auth/domain/ports/auth_port.dart';
        addFile(path, '''
        // Returns 'String', but only 'FutureEither' is allowed
        abstract interface class AuthPort {
          String getName(); 
        }
      ''');

        final lints = await runLint(
          filePath: path,
          typeSafeties: [
            {
              'on': ['port'],
              'allowed': [
                {'kind': 'return', 'type': 'FutureEither'},
              ],
            },
          ],
        );

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('Expected type `FutureEither`'));
      },
    );

    test(
      'should report violation when parameter matching identifier uses Forbidden type',
      () async {
        const path = 'lib/features/user/domain/ports/user_repo.dart';
        addFile(path, '''
        abstract class UserRepo {
          // VIOLATION: 'id' param uses 'int'
          void getUser(int id); 
        }
      ''');

        final lints = await runLint(
          filePath: path,
          typeSafeties: [
            {
              'on': ['port'],
              'forbidden': [
                {'kind': 'parameter', 'identifier': 'id', 'type': 'int'},
              ],
              'allowed': [
                {'kind': 'parameter', 'identifier': 'id', 'type': 'IntId'},
              ],
            },
          ],
        );

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('Use `IntId` instead of `int`'));
      },
    );

    test('should use type_definitions to resolve Forbidden types', () async {
      const path = 'lib/features/user/domain/ports/user_repo.dart';
      addFile(path, '''
        import 'dart:async';
        abstract class UserRepo {
          // VIOLATION: Future matches 'result.future' definition
          Future<void> save(); 
        }
      ''');

      final lints = await runLint(
        filePath: path,
        // FIX: Correct list structure for type definitions:
        // 'group': [ {'key': 'key_name', 'name': 'TypeName'} ]
        typeDefinitions: {
          'result': [
            {'key': 'future', 'name': 'Future'},
          ],
        },
        typeSafeties: [
          {
            'on': ['port'],
            'forbidden': [
              {'kind': 'return', 'definition': 'result.future'},
            ],
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Usage of `Future` is forbidden'));
    });

    test('should not report violation when parameter identifier does not match rule', () async {
      const path = 'lib/features/user/domain/ports/user_repo.dart';
      addFile(path, '''
        abstract class UserRepo {
          // 'int' is forbidden for 'id', but this is 'age'
          void updateAge(int age); 
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeSafeties: [
          {
            'on': ['port'],
            'forbidden': [
              {'kind': 'parameter', 'identifier': 'id', 'type': 'int'},
            ],
          },
        ],
      );

      expect(lints, isEmpty);
    });
  });
}
