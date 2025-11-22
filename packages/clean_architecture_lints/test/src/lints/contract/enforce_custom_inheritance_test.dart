// test/src/lints/contract/enforce_custom_inheritance_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_custom_inheritance.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceCustomInheritance Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('custom_inheritance_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );

      // Setup core classes for inheritance checks
      addFile('lib/core/base_widget.dart', 'abstract class BaseWidget {}');
      addFile('lib/core/special_widget.dart', 'abstract class SpecialWidget {}');
      addFile('lib/core/forbidden_mixin.dart', 'mixin ForbiddenMixin {}');
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
      required List<Map<String, dynamic>> inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(inheritances: inheritances);
      final lint = EnforceCustomInheritance(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    group('Required Rule', () {
      final requiredRule = {
        'on': 'widget',
        'required': {'name': 'BaseWidget', 'import': 'package:test_project/core/base_widget.dart'},
      };

      test('reports violation when required supertype is missing', () async {
        const path = 'lib/features/home/presentation/widgets/my_widget.dart';
        addFile(path, 'class MyWidget {}');

        final lints = await runLint(
          filePath: path,
          inheritances: [requiredRule],
        );

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('must extend or implement one of: BaseWidget'));
      });

      test('does not report violation when required supertype is present', () async {
        const path = 'lib/features/home/presentation/widgets/my_widget.dart';
        addFile(path, '''
          import 'package:test_project/core/base_widget.dart';
          class MyWidget extends BaseWidget {}
        ''');

        final lints = await runLint(
          filePath: path,
          inheritances: [requiredRule],
        );
        expect(lints, isEmpty);
      });
    });

    group('Forbidden Rule', () {
      final forbiddenRule = {
        'on': 'widget',
        'forbidden': {
          'name': 'ForbiddenMixin',
          'import': 'package:test_project/core/forbidden_mixin.dart',
        },
      };

      test('reports violation when forbidden supertype is used', () async {
        const path = 'lib/features/home/presentation/widgets/my_widget.dart';
        addFile(path, '''
          import 'package:test_project/core/forbidden_mixin.dart';
          class MyWidget with ForbiddenMixin {}
        ''');

        final lints = await runLint(
          filePath: path,
          inheritances: [forbiddenRule],
        );

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('must not extend or implement ForbiddenMixin'));
      });

      test('does not report violation when forbidden supertype is NOT used', () async {
        const path = 'lib/features/home/presentation/widgets/my_widget.dart';
        addFile(path, 'class MyWidget {}');

        final lints = await runLint(
          filePath: path,
          inheritances: [forbiddenRule],
        );
        expect(lints, isEmpty);
      });
    });

    group('Allowed (Override) Logic', () {
      // This checks if the "allowed" list correctly bypasses other checks.
      // Scenario: Widgets MUST extend BaseWidget, BUT SpecialWidget is also acceptable.

      final combinedRule = {
        'on': 'widget',
        'required': {
          'name': 'BaseWidget',
          'import': 'package:test_project/core/base_widget.dart',
        },
        'allowed': {
          'name': 'SpecialWidget',
          'import': 'package:test_project/core/special_widget.dart',
        },
      };

      test('reports violation if neither required nor allowed types are used', () async {
        const path = 'lib/features/home/presentation/widgets/my_widget.dart';
        addFile(path, 'class MyWidget {}');

        final lints = await runLint(
          filePath: path,
          inheritances: [combinedRule],
        );

        // Should trigger the 'required' error because we didn't match the allowed list either.
        expect(lints, hasLength(1));
        expect(lints.first.message, contains('must extend or implement one of: BaseWidget'));
      });

      test('passes if class extends the Allowed type (skipping required check)', () async {
        const path = 'lib/features/home/presentation/widgets/my_widget.dart';
        // Extends SpecialWidget, which is NOT BaseWidget, but it IS allowed.
        addFile(path, '''
          import 'package:test_project/core/special_widget.dart';
          class MyWidget extends SpecialWidget {}
        ''');

        final lints = await runLint(
          filePath: path,
          inheritances: [combinedRule],
        );
        expect(lints, isEmpty);
      });
    });
  });
}
