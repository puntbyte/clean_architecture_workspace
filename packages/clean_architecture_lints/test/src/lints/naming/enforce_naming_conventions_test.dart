// test/src/lints/naming/enforce_naming_conventions_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_naming_conventions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceNamingConventions Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('naming_conventions_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );
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
      required List<Map<String, dynamic>> namingRules,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(namingRules: namingRules);
      final lint = EnforceNamingConventions(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when class name does not match the required pattern', () async {
      final path = 'lib/features/user/data/models/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'model', 'pattern': '{{name}}Model'},
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('does not match the required `{{name}}Model`'));
    });

    test('reports violation when class name matches a forbidden anti-pattern', () async {
      final path = 'lib/features/user/domain/entities/user_entity.dart';
      addFile(path, 'class UserEntity {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'entity', 'pattern': '{{name}}', 'antipattern': '{{name}}Entity'},
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('uses a forbidden pattern'));
    });

    test('does not report violation when class name follows all conventions', () async {
      final path = 'lib/features/user/data/models/user_model.dart';
      addFile(path, 'class UserModel {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'model', 'pattern': '{{name}}Model'},
        ],
      );
      expect(lints, isEmpty);
    });

    test('should be silent when a file is clearly mislocated (handled by location lint)', () async {
      // A class named `UserModel` (a Model) is in an `entities` directory (for Entities).
      // The location lint will flag this. This naming lint should stay quiet.
      final path = 'lib/features/user/domain/entities/user_model.dart';
      addFile(path, 'class UserModel {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'model', 'pattern': '{{name}}Model'},
          {'on': 'entity', 'pattern': '{{name}}'},
        ],
      );

      expect(
        lints,
        isEmpty,
        reason: 'Mislocation issues should be ignored by the naming lint.',
      );
    });

    test('does not report violation when no naming rule is defined for the component', () async {
      final path = 'lib/features/user/data/models/user_model.dart';
      addFile(path, 'class UserModel {}');

      // No rule for 'model' is provided.
      final lints = await runLint(filePath: path, namingRules: []);
      expect(lints, isEmpty);
    });
  });
}