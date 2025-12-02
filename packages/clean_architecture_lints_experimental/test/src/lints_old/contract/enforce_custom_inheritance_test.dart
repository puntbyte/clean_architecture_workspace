// test/src/lints/contract/enforce_custom_inheritance_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/contract/enforce_custom_inheritance.dart';
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
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Setup classes
      addFile('lib/core/base_widget.dart', 'abstract class BaseWidget {}');
      addFile('lib/core/forbidden_mixin.dart', 'mixin ForbiddenMixin {}');
      addFile('lib/features/user/domain/entities/user.dart', 'class User {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(inheritances: inheritances);
      final lint = EnforceCustomInheritance(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    group('Specific Class Inheritance', () {
      final requiredRule = {
        'on': 'widget',
        'required': {
          'name': 'BaseWidget',
          'import': 'package:test_project/core/base_widget.dart'
        },
      };

      test('reports violation when required specific supertype is missing', () async {
        final path = 'lib/features/home/presentation/widgets/my_widget.dart';
        addFile(path, 'class MyWidget {}');

        final lints = await runLint(
          filePath: path,
          inheritances: [requiredRule],
        );

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('must extend or implement one of: BaseWidget'));
      });

      test('reports violation when forbidden specific supertype is present', () async {
        final forbiddenRule = {
          'on': 'widget',
          'forbidden': {
            'name': 'ForbiddenMixin',
            'import': 'package:test_project/core/forbidden_mixin.dart',
          },
        };

        final path = 'lib/features/home/presentation/widgets/my_widget.dart';
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
    });

    group('Component-Based Inheritance', () {
      final modelRule = {
        'on': 'model',
        'required': {'component': 'entity'},
      };

      test('reports violation when Model does not extend any Entity', () async {
        final path = 'lib/features/user/data/models/user_model.dart';
        addFile(path, 'class UserModel {}');

        final lints = await runLint(
          filePath: path,
          inheritances: [modelRule],
        );

        expect(lints, hasLength(1));
        // Now expects 'Entity' (capitalized Label), which fixes the previous error.
        expect(lints.first.message, contains('must extend or implement one of: Entity'));
      });

      test('does NOT report violation when Model extends a valid Entity', () async {
        final path = 'lib/features/user/data/models/user_model.dart';
        addFile(path, '''
          import '../../domain/entities/user.dart';
          class UserModel extends User {}
        ''');

        final lints = await runLint(
          filePath: path,
          inheritances: [modelRule],
        );

        expect(lints, isEmpty);
      });
    });

    test('Allowed rule override works for Component-based checks', () async {
      final combinedRule = {
        'on': 'model',
        'required': {'component': 'entity'},
        'allowed': {
          'name': 'SpecialBase',
          'import': 'package:test_project/core/special_base.dart'
        },
      };

      addFile('lib/core/special_base.dart', 'class SpecialBase {}');
      final path = 'lib/features/user/data/models/special_model.dart';
      addFile(path, '''
        import 'package:test_project/core/special_base.dart';
        class SpecialModel extends SpecialBase {}
      ''');

      final lints = await runLint(
        filePath: path,
        inheritances: [combinedRule],
      );

      expect(lints, isEmpty);
    });
  });
}