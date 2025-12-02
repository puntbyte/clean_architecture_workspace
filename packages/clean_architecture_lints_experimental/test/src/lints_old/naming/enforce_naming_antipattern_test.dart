import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/naming/enforce_naming_antipattern.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('EnforceNamingAntipattern Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('naming_antipattern_test_');
      testProjectPath = p.canonicalize(tempDir.path);
      addFile('pubspec.yaml', 'name: example');
      addFile('.dart_tool/package_config.json', '{"configVersion": 2, "packages": []}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> namingRules,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
      await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
      as ResolvedUnitResult;
      final config = makeConfig(namingRules: namingRules);
      final lint = EnforceNamingAntipattern(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when class name matches forbidden anti-pattern', () async {
      const path = 'lib/features/user/domain/entities/user_entity.dart';
      addFile(path, 'class UserEntity {}'); // Matches {{name}}Entity

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'entity', 'pattern': '{{name}}', 'antipattern': '{{name}}Entity'},
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('uses a forbidden pattern'));
    });

    test('does NOT report violation if class name matches pattern but NOT anti-pattern', () async {
      const path = 'lib/features/user/domain/entities/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'entity', 'pattern': '{{name}}', 'antipattern': '{{name}}Entity'},
        ],
      );
      expect(lints, isEmpty);
    });

    test('does NOT report violation for UncontractedUser (does not match anti-pattern)', () async {
      const path = 'lib/features/user/domain/entities/uncontracted_user.dart';
      addFile(path, 'class UncontractedUser {}');

      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'entity', 'pattern': '{{name}}', 'antipattern': '{{name}}Entity'},
        ],
      );
      expect(lints, isEmpty);
    });
  });
}