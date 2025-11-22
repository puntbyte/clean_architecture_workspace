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

    // Helper to write files safely using canonical paths
    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      // [Windows Fix] Use canonical path
      tempDir = Directory.systemTemp.createTempSync('enforce_annotations_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Define some dummy annotations for testing.
      addFile('lib/annotations.dart', '''
        const injectable = Injectable();
        class Injectable { const Injectable(); }
        class Forbidden { const Forbidden(); }
      ''');
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
      required List<Map<String, dynamic>> annotations,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(annotations: annotations);
      final lint = EnforceAnnotations(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    group('Required Rule', () {
      final requiredRule = {
        'on': ['usecase'],
        'required': {'name': 'Injectable'},
      };

      test('reports violation when a use case is missing a required annotation', () async {
        final path = 'lib/features/auth/domain/usecases/login.dart';
        addFile(path, 'class Login {}');

        final lints = await runLint(filePath: path, annotations: [requiredRule]);

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('missing the required `@Injectable`'));
      });

      test('does not report violation when a use case has the required annotation', () async {
        final path = 'lib/features/auth/domain/usecases/login.dart';
        addFile(path, '''
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
        'on': ['entity'],
        'forbidden': {'name': 'Forbidden'},
      };

      test('reports violation when an entity has a forbidden annotation', () async {
        final path = 'lib/features/user/domain/entities/user.dart';
        addFile(path, '''
          import 'package:test_project/annotations.dart';
          @Forbidden()
          class User {}
        ''');

        final lints = await runLint(filePath: path, annotations: [forbiddenRule]);

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('must not have the `@Forbidden` annotation'));
      });
    });

    group('Allowed Rule', () {
      final allowedRule = {
        'on': ['model'],
        'allowed': {'name': 'Injectable'}, // Allowed means optional, but permitted.
      };

      test('does not report violation when an allowed annotation is missing', () async {
        final path = 'lib/features/user/data/models/user_model.dart';
        addFile(path, 'class UserModel {}');

        final lints = await runLint(filePath: path, annotations: [allowedRule]);

        expect(
          lints,
          isEmpty,
          reason: 'Allowed annotations are optional.',
        );
      });
    });
  });
}