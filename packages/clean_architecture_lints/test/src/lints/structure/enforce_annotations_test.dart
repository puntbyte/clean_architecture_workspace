// test/src/lints/structure/enforce_annotations_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/structure/enforce_annotations.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceAnnotations Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('enforce_annotations_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');
      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {"name": "example", "rootUri": "$libUri", "packageUri": "."},
          {"name": "injectable", "rootUri": "$libUri", "packageUri": "."} 
        ]
      }
      ''');

      // Define dummy annotations
      addFile('lib/injectable.dart', '''
        class Injectable { const Injectable(); }
        class LazySingleton { const LazySingleton(); }
      ''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> annotations,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(annotations: annotations);
      final lint = EnforceAnnotations(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    group('Forbidden Rule', () {
      final forbiddenInjectableRule = {
        'on': 'entity',
        'forbidden': {'name': 'Injectable', 'import': 'package:injectable/injectable.dart'},
      };

      test('should report violation when a forbidden package is imported', () async {
        const path = 'lib/features/user/domain/entities/user_import.dart';
        addFile(path, '''
          import 'package:injectable/injectable.dart'; // VIOLATION
          class User {}
        ''');

        final lints = await runLint(
          filePath: path,
          annotations: [forbiddenInjectableRule],
        );

        expect(lints, isNotEmpty);
        expect(
          lints.any(
            (l) => l.message.contains('import `package:injectable/injectable.dart` is forbidden'),
          ),
          isTrue,
          reason: 'Should flag the import statement',
        );
      });

      test('should report violation when a class uses a forbidden annotation', () async {
        const path = 'lib/features/user/domain/entities/user_usage.dart';
        addFile(path, '''
          import 'package:injectable/injectable.dart';
          
          @Injectable() // VIOLATION
          class User {}
        ''');

        final lints = await runLint(
          filePath: path,
          annotations: [forbiddenInjectableRule],
        );

        expect(
          lints.any((l) => l.message.contains('must not have the `@Injectable` annotation')),
          isTrue,
          reason: 'Should flag the annotation usage',
        );
      });

      test('should match forbidden annotation case-insensitively (e.g. @lazySingleton)', () async {
        final forbiddenLazyRule = {
          'on': 'entity',
          'forbidden': {'name': 'LazySingleton', 'import': 'package:injectable/injectable.dart'},
        };

        const path = 'lib/features/user/domain/entities/user_alias.dart';
        addFile(path, '''
          import 'package:injectable/injectable.dart';
          
          @lazySingleton // Lowercase alias usage
          class User {}
        ''');

        final lints = await runLint(
          filePath: path,
          annotations: [forbiddenLazyRule],
        );

        expect(
          lints.any((l) => l.message.contains('must not have the `@LazySingleton` annotation')),
          isTrue,
        );
      });

      test(
        'should report violation based on name-only config if import is not specified',
        () async {
          final nameOnlyRule = {
            'on': 'entity',
            'forbidden': {'name': 'Injectable'}, // No import URI
          };

          const path = 'lib/features/user/domain/entities/user_simple.dart';
          addFile(path, '''
          @Injectable() 
          class User {}
        ''');

          final lints = await runLint(
            filePath: path,
            annotations: [nameOnlyRule],
          );

          expect(lints, hasLength(1));
          expect(lints.first.message, contains('must not have the `@Injectable` annotation'));
        },
      );

      test(
        'should NOT report violation if name matches but import URI does not match config',
        () async {
          final strictImportRule = {
            'on': 'entity',
            'forbidden': {
              'name': 'Injectable',
              'import': 'package:other_lib/other.dart', // Different package
            },
          };

          const path = 'lib/features/user/domain/entities/user_safe.dart';
          addFile(path, '''
          import 'package:injectable/injectable.dart'; // Matches name, but wrong URI
          @Injectable()
          class User {}
        ''');

          final lints = await runLint(
            filePath: path,
            annotations: [strictImportRule],
          );

          expect(lints, isEmpty, reason: 'Annotation name matches but source URI differs');
        },
      );
    });

    group('Required Rule', () {
      final requiredRule = {
        'on': 'usecase',
        'required': {'name': 'Injectable'},
      };

      test('should report violation when required annotation is missing', () async {
        const path = 'lib/features/auth/domain/usecases/login.dart';
        addFile(path, 'class Login {}');

        final lints = await runLint(
          filePath: path,
          annotations: [requiredRule],
        );

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('missing the required `@Injectable` annotation'));
      });

      test('should not report violation when required annotation is present', () async {
        const path = 'lib/features/auth/domain/usecases/login_valid.dart';
        addFile(path, '''
          @Injectable()
          class Login {}
        ''');

        final lints = await runLint(
          filePath: path,
          annotations: [requiredRule],
        );

        expect(lints, isEmpty);
      });
    });

    group('Mixed Rules', () {
      test('should support simultaneous forbidden and required checks', () async {
        final mixedRule = {
          'on': 'entity',
          'required': {'name': 'Entity'},
          'forbidden': {'name': 'Injectable'},
        };

        const path = 'lib/features/user/domain/entities/user_mixed.dart';
        // Missing @Entity (Required error) AND has @Injectable (Forbidden error)
        addFile(path, '''
          @Injectable()
          class User {}
        ''');

        final lints = await runLint(
          filePath: path,
          annotations: [mixedRule],
        );

        expect(lints, hasLength(2));
        expect(lints.any((l) => l.message.contains('missing the required `@Entity`')), isTrue);
        expect(lints.any((l) => l.message.contains('must not have the `@Injectable`')), isTrue);
      });
    });
  });
}
