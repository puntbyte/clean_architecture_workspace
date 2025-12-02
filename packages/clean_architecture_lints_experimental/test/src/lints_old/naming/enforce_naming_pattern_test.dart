import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/naming/enforce_naming_pattern.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('EnforceNamingPattern Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('naming_pattern_test_');
      testProjectPath = p.canonicalize(tempDir.path);
      addFile('pubspec.yaml', 'name: example');
      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {"name": "example", "rootUri": "$libUri", "packageUri": "."}
        ]
      }
      ''');
      addFile('lib/features/user/domain/entities/user.dart', 'class User {}');
    });

    tearDown(() {
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> namingRules,
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit = await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(namingRules: namingRules, inheritances: inheritances);
      final lint = EnforceNamingPattern(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when class name does not match the required pattern', () async {
      const path = 'lib/features/user/data/models/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [{'on': 'model', 'pattern': '{{name}}Model'}],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('does not match the required `{{name}}Model`'));
    });

    test('Does NOT yield (Reports Naming) if inheritance is valid', () async {
      // Scenario: UserDTO extends User (Entity). Located in Models.
      // Name: UserDTO (Does not match {{name}}Model).
      // Inheritance: Valid (Model must extend Entity).
      // Expected: EnforceNamingPattern should REPORT error (Bad Name), not yield.

      const path = 'lib/features/user/data/models/user_dto.dart';
      // Using relative import to ensure resolution
      addFile(path, '''
        import '../../domain/entities/user.dart';
        class UserDTO extends User {}
      ''');

      final lints = await runLint(
          filePath: path,
          namingRules: [
            {'on': 'model', 'pattern': '{{name}}Model'},
            {'on': 'entity', 'pattern': '{{name}}'}
          ],
          inheritances: [
            {'on': 'model', 'required': {'component': 'entity'}}
          ]
      );

      expect(lints, hasLength(1));
      // It should be a naming error, not empty (which would mean it yielded)
      expect(lints.first.errorCode.name, 'enforce_naming_pattern');
      expect(lints.first.message, contains('does not match the required `{{name}}Model`'));
    });
  });
}
