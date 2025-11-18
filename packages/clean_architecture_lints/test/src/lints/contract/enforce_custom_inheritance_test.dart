// test/srcs/lints/contract/enforce_custom_inheritance_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_custom_inheritance.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceCustomInheritance Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;
    late String testProjectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> inheritances,
    }) async {
      final config = makeConfig(inheritances: inheritances);
      final lint = EnforceCustomInheritance(config: config, layerResolver: LayerResolver(config));

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
      tempDir = Directory.systemTemp.createTempSync('custom_inheritance_test_');
      projectPath = p.normalize(tempDir.path);
      testProjectPath = p.join(projectPath, 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(testProjectPath, '.dart_tool/package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
        '"packageUri": "lib/"}]}',
      );

      writeFile(
        p.join(testProjectPath, 'lib/core/base_widget.dart'),
        'abstract class BaseWidget {}',
      );
      writeFile(
        p.join(testProjectPath, 'lib/core/special_widget.dart'),
        'abstract class SpecialWidget extends BaseWidget {}',
      );
      writeFile(
        p.join(testProjectPath, 'lib/core/forbidden_mixin.dart'),
        'mixin ForbiddenMixin {}',
      );

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('Required Rule', () {
      final requiredRule = {
        'on': 'widget',
        'required': {'name': 'BaseWidget', 'import': 'package:test_project/core/base_widget.dart'},
      };

      test('should report violation when a widget does not have the required supertype', () async {
        final path = p.join(
          testProjectPath,
          'lib/features/home/presentation/widgets/home_button.dart',
        );
        writeFile(path, 'class HomeButton {}');

        final lints = await runLint(filePath: path, inheritances: [requiredRule]);

        expect(lints, hasLength(1));
        expect(lints.first.diagnosticCode.name, 'custom_inheritance_required');
      });

      test('should not report violation when a widget has the required supertype', () async {
        final path = p.join(
          testProjectPath,
          'lib/features/home/presentation/widgets/home_button.dart',
        );
        writeFile(path, '''
          import 'package:test_project/core/base_widget.dart';
          class HomeButton extends BaseWidget {}
        ''');

        final lints = await runLint(filePath: path, inheritances: [requiredRule]);
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

      test('should report violation when a widget has a forbidden supertype', () async {
        final path = p.join(
          testProjectPath,
          'lib/features/home/presentation/widgets/home_button.dart',
        );
        writeFile(path, '''
          import 'package:test_project/core/forbidden_mixin.dart';
          class HomeButton with ForbiddenMixin {}
        ''');

        final lints = await runLint(filePath: path, inheritances: [forbiddenRule]);

        expect(lints, hasLength(1));
        expect(lints.first.diagnosticCode.name, 'custom_inheritance_forbidden');
      });
    });

    group('Allowed Rule Interaction', () {
      test(
        'should not report violation when a required rule is unmet but an allowed rule is met',
        () async {
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
          final path = p.join(
            testProjectPath,
            'lib/features/home/presentation/widgets/home_button.dart',
          );
          writeFile(path, '''
          import 'package:test_project/core/special_widget.dart';
          class HomeButton extends SpecialWidget {}
        ''');

          final lints = await runLint(filePath: path, inheritances: [combinedRule]);
          expect(lints, isEmpty, reason: 'Allowed supertype should override the required check.');
        },
      );

      test(
        'should not report violation when a forbidden rule is met but an allowed rule is also met',
        () async {
          // This tests a rule like "don't extend Base, but it's okay if you extend Special which
          // extends Base"
          final combinedRule = {
            'on': 'widget',
            'forbidden': {
              'name': 'BaseWidget',
              'import': 'package:test_project/core/base_widget.dart',
            },
            'allowed': {
              'name': 'SpecialWidget',
              'import': 'package:test_project/core/special_widget.dart',
            },
          };
          final path = p.join(
            testProjectPath,
            'lib/features/home/presentation/widgets/home_button.dart',
          );
          writeFile(path, '''
          import 'package:test_project/core/special_widget.dart';
          class HomeButton extends SpecialWidget {} // SpecialWidget extends BaseWidget
        ''');

          final lints = await runLint(filePath: path, inheritances: [combinedRule]);
          expect(lints, isEmpty, reason: 'Allowed supertype should override the forbidden check.');
        },
      );
    });
  });
}
