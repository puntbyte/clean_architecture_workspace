// test/src/lints/structure/enforce_annotations_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/structure/enforce_annotations.dart';
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

      // Define dummy annotations in the fake 'injectable' package.
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

    group('Forbidden rules', () {
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

        expect(lints, isNotEmpty, reason: 'Import of forbidden package must produce a lint');
        expect(
          lints.any(
            (l) => l.message.contains('import `package:injectable/injectable.dart` is forbidden'),
          ),
          isTrue,
          reason: 'Should flag the import directive message',
        );
      });

      test(
        'should report violation when a class uses a forbidden annotation (simple form)',
        () async {
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
            reason: 'Annotation usage should be flagged',
          );
        },
      );

      test(
        'should report violation when a class uses a forbidden annotation (lowercase token)',
        () async {
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
            reason: 'Lowercase annotation token should match case-insensitively',
          );
        },
      );

      test(
        'should report violation when a class uses a forbidden annotation with prefix',
        () async {
          final prefixedRule = {
            'on': 'entity',
            'forbidden': {'name': 'Injectable', 'import': 'package:injectable/injectable.dart'},
          };

          const path = 'lib/features/user/domain/entities/user_prefixed.dart';
          addFile(path, '''
          import 'package:injectable/injectable.dart' as i;
          
          @i.Injectable()
          class User {}
        ''');

          final lints = await runLint(
            filePath: path,
            annotations: [prefixedRule],
          );

          expect(
            lints.any((l) => l.message.contains('must not have the `@Injectable` annotation')),
            isTrue,
            reason: 'Prefixed annotation (@i.Injectable) should be detected and flagged',
          );
        },
      );

      test('should report violation with name-only config when import is not specified', () async {
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

        expect(lints, hasLength(1), reason: 'Name-only rule should flag the annotation once');
        expect(lints.first.message, contains('must not have the `@Injectable` annotation'));
      });

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

          expect(
            lints,
            isEmpty,
            reason: 'Should not flag when import URI does not match configured forbidden import',
          );
        },
      );
    });

    group('Required rules', () {
      test('should report violation when required annotation is missing (simple)', () async {
        final requiredRule = {
          'on': 'usecase',
          'required': {'name': 'Injectable'},
        };

        const path = 'lib/features/auth/domain/usecases/login.dart';
        addFile(path, 'class Login {}');

        final lints = await runLint(
          filePath: path,
          annotations: [requiredRule],
        );

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('missing the required `@Injectable` annotation'));
      });

      test(
        'should not report violation when required annotation is present (annotation only)',
        () async {
          final requiredRule = {
            'on': 'usecase',
            'required': {'name': 'Injectable'},
          };

          const path = 'lib/features/auth/domain/usecases/login_valid.dart';
          addFile(path, '''
          @Injectable()
          class Login {}
        ''');

          final lints = await runLint(
            filePath: path,
            annotations: [requiredRule],
          );

          expect(lints, isEmpty, reason: 'Presence of @Injectable should satisfy required rule');
        },
      );

      test(
        'should not report violation when required annotation is present with import (package match)',
        () async {
          final requiredRuleWithImport = {
            'on': 'usecase',
            'required': {'name': 'injectable', 'import': 'package:injectable/injectable.dart'},
          };

          const path = 'lib/features/auth/domain/usecases/logout.dart';
          addFile(path, '''
          import 'package:injectable/injectable.dart';

          @Injectable()
          class Logout {}
        ''');

          final lints = await runLint(
            filePath: path,
            annotations: [requiredRuleWithImport],
          );

          expect(
            lints,
            isEmpty,
            reason:
                'Required rule with import should be satisfied by @Injectable and matching import',
          );
        },
      );

      test(
        'should not report violation when required annotation is present with prefixed import',
        () async {
          final requiredRuleWithImport = {
            'on': 'usecase',
            'required': {'name': 'Injectable', 'import': 'package:injectable/injectable.dart'},
          };

          const path = 'lib/features/auth/domain/usecases/logout_prefixed.dart';
          addFile(path, '''
          import 'package:injectable/injectable.dart' as i;

          @i.Injectable()
          class Logout {}
        ''');

          final lints = await runLint(
            filePath: path,
            annotations: [requiredRuleWithImport],
          );

          expect(
            lints,
            isEmpty,
            reason: 'Prefixed import with @i.Injectable should satisfy required rule',
          );
        },
      );
    });

    group('Mixed rules', () {
      test(
        'should report both missing required and forbidden annotation violations when applicable',
        () async {
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

          // Expect 2 diagnostics: one for missing required, one for forbidden annotation
          expect(lints, hasLength(2));
          expect(lints.any((l) => l.message.contains('missing the required `@Entity`')), isTrue);
          expect(lints.any((l) => l.message.contains('must not have the `@Injectable`')), isTrue);
        },
      );
    });
  });
}
