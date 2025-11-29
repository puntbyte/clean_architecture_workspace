// test/src/lints/structure/enforce_type_safety_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/type_safety/enforce_type_safety.dart';
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

      addFile('pubspec.yaml', 'name: feature_first_example');

      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {"name": "feature_first_example", "rootUri": "$libUri", "packageUri": "."}
        ]
      }
      ''');

      // Define types
      addFile('lib/core/utils/types.dart', '''
        class FutureEither<T> {} 
        typedef IntId = int;
        typedef StringId = String;
      ''');

      addFile('lib/features/auth/domain/entities/user.dart', 'class User {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? typeSafeties,
      Map<String, dynamic>? typeDefinitions,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(
        typeDefinitions:
            typeDefinitions ??
            {
              'result': [
                {'key': 'future', 'name': 'Future'},
                {
                  'key': 'wrapper',
                  'name': 'FutureEither',
                  'import': 'package:feature_first_example/core/utils/types.dart',
                },
              ],
              'identity': [
                {
                  'key': 'integer',
                  'name': 'IntId',
                  'import': 'package:feature_first_example/core/utils/types.dart',
                },
                {
                  'key': 'string',
                  'name': 'StringId',
                  'import': 'package:feature_first_example/core/utils/types.dart',
                },
              ],
            },
        typeSafeties: typeSafeties,
      );

      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('LINT [8]: Return type must be FutureEither, not raw Future', () async {
      const path = 'lib/features/auth/domain/ports/auth_port.dart';
      addFile(path, '''
        import 'package:feature_first_example/features/auth/domain/entities/user.dart';
        
        abstract interface class AuthPort {
          // Violation: Returns Future<User> instead of FutureEither
          Future<User> login(String username); 
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeSafeties: [
          {
            'on': ['port'],
            'allowed': [
              {'kind': 'return', 'type': 'result.wrapper'},
            ],
            'forbidden': [
              {'kind': 'return', 'type': 'result.future'},
            ],
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Usage of `Future` is forbidden'));
    });

    test('LINT [9]: Parameter named "id" must be IntId, not int', () async {
      const path = 'lib/features/auth/domain/ports/auth_port.dart';
      addFile(path, '''
        import 'package:feature_first_example/core/utils/types.dart';
        import 'package:feature_first_example/features/auth/domain/entities/user.dart';
        
        abstract interface class AuthPort {
          // Violation: int id
          FutureEither<User> getUser(int id);
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeSafeties: [
          {
            'on': ['port'],
            'allowed': [
              {'kind': 'parameter', 'identifier': 'id', 'type': 'identity.integer'},
            ],
            'forbidden': [
              {'kind': 'parameter', 'identifier': 'id', 'type': 'int'},
            ],
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(
        lints.first.message.contains('Usage of `int` is forbidden') ||
            lints.first.message.contains('Expected type `IntId`'),
        isTrue,
      );
    });

    test('LINT [10]: Parameter named "id" must be StringId, not String', () async {
      const path = 'lib/features/auth/domain/ports/auth_port.dart';
      addFile(path, '''
        import 'package:feature_first_example/core/utils/types.dart';
        
        abstract interface class AuthPort {
          // Violation: String id
          FutureEither<void> deleteUser(String id);
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeSafeties: [
          {
            'on': ['port'],
            'allowed': [
              {'kind': 'parameter', 'identifier': 'id', 'type': 'identity.string'},
            ],
            'forbidden': [
              {'kind': 'parameter', 'identifier': 'id', 'type': 'String'},
            ],
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Usage of `String` is forbidden'));
    });

    test('Valid: Correct types used (Alias)', () async {
      const path = 'lib/features/auth/domain/ports/auth_port.dart';
      addFile(path, '''
        import 'package:feature_first_example/core/utils/types.dart';
        import 'package:feature_first_example/features/auth/domain/entities/user.dart';
        
        abstract interface class AuthPort {
          FutureEither<User> getUser(IntId id); 
          FutureEither<void> deleteUser(StringId id);
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeSafeties: [
          {
            'on': ['port'],
            'allowed': [
              {'kind': 'return', 'type': 'result.wrapper'},
              {'kind': 'parameter', 'identifier': 'id', 'type': 'identity.integer'},
              {'kind': 'parameter', 'identifier': 'id', 'type': 'identity.string'},
            ],
            'forbidden': [
              {'kind': 'return', 'type': 'result.future'},
              {'kind': 'parameter', 'identifier': 'id', 'type': 'int'},
              {'kind': 'parameter', 'identifier': 'id', 'type': 'String'},
            ],
          },
        ],
      );

      expect(lints, isEmpty);
    });
  });
}
