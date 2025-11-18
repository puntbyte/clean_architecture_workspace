// test/srcs/lints/structure/enforce_annotations_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/structure/enforce_annotations.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceAnnotations Lint', () {
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

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> annotations,
    }) async {
      final config = makeConfig(annotations: annotations);
      final lint = EnforceAnnotations(config: config, layerResolver: LayerResolver(config));

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
      tempDir = Directory.systemTemp.createTempSync('enforce_annotations_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      // Define some dummy annotations for testing.
      writeFile(p.join(testProjectPath, 'lib/annotations.dart'), '''
        const injectable = Injectable();
        class Injectable { const Injectable(); }
        class Forbidden { const Forbidden(); }
      ''');
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('Required Rule', () {
      final requiredRule = {
        'on': 'usecase',
        'required': {'name': 'Injectable'},
      };

      test('should report violation when a use case is missing a required annotation', () async {
        final path = p.join(testProjectPath, 'lib/features/auth/domain/usecases/login.dart');
        writeFile(path, 'class Login {}');

        final lints = await runLint(filePath: path, annotations: [requiredRule]);

        expect(lints, hasLength(1));
        expect(lints.first.diagnosticCode.name, 'enforce_annotations_required');
        expect(
          lints.first.problemMessage.messageText(includeUrl: false),
          'This Use Case is missing the required `@Injectable` annotation.',
        );
      });

      test('should not report violation when a use case has the required annotation', () async {
        final path = p.join(testProjectPath, 'lib/features/auth/domain/usecases/login.dart');
        writeFile(path, '''
          import 'package:test_project/annotations.dart';
          @Injectable()
          class Login {}
        ''');

        final lints = await runLint(filePath: path, annotations: [requiredRule]);
        expect(lints, isEmpty);
      });
    });

    group('Forbidden Rule', () {
      final forbiddenRule = {
        'on': 'entity',
        'forbidden': {'name': 'Forbidden'},
      };

      test('should report violation when an entity has a forbidden annotation', () async {
        final path = p.join(testProjectPath, 'lib/features/user/domain/entities/user.dart');
        writeFile(path, '''
          import 'package:test_project/annotations.dart';
          @Forbidden()
          class User {}
        ''');

        final lints = await runLint(filePath: path, annotations: [forbiddenRule]);

        expect(lints, hasLength(1));
        expect(lints.first.diagnosticCode.name, 'enforce_annotations_forbidden');
        expect(
          lints.first.problemMessage.messageText(includeUrl: false),
          'This Entity must not have the `@Forbidden` annotation.',
        );
      });
    });

    group('Allowed Rule', () {
      final allowedRule = {
        'on': 'model',
        'allowed': {'name': 'Injectable'},
      };

      test('should not report violation when an allowed annotation is missing', () async {
        final path = p.join(testProjectPath, 'lib/features/user/data/models/user_model.dart');
        writeFile(path, 'class UserModel {}');

        final lints = await runLint(filePath: path, annotations: [allowedRule]);

        expect(
          lints,
          isEmpty,
          reason: 'Allowed annotations are optional and should not trigger a lint if absent.',
        );
      });
    });
  });
}
