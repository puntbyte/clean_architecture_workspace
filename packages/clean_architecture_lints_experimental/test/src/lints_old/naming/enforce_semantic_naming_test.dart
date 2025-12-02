

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/naming/enforce_semantic_naming.dart';
import 'package:architecture_lints/src/utils/nlp/language_analyzer.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceSemanticNaming Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;
    late LanguageAnalyzer analyzer;

    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('semantic_naming_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile('.dart_tool/package_config.json', '{"configVersion": 2, "packages": []}');

      analyzer = LanguageAnalyzer(
        posOverrides: {
          'user': {'NOUN'},
          'list': {'NOUN'},
          'auth': {'NOUN'},
          'contract': {'NOUN'}, // Added to test suffix logic
        },
      );
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
      final lint = EnforceSemanticNaming(
        config: config,
        layerResolver: LayerResolver(config),
        analyzer: analyzer,
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    group('Suffix / Pattern Interaction', () {
      test('Ignores suffix mismatch (delegates to enforce_naming_pattern)', () async {
        // Grammar: {{noun.phrase}}Port
        // Class: AuthContract (Should fail syntax check, but pass semantic check)
        // Reason: If we checked semantics, "AuthContract" -> base "AuthContract".
        // But we assume "Port" is required. Since it's missing, we skip.

        final portRule = {'on': 'port', 'grammar': '{{noun.phrase}}Port'};

        const path = 'lib/features/user/domain/ports/auth_contract.dart';
        addFile(path, 'abstract interface class AuthContract {}');

        final lints = await runLint(filePath: path, namingRules: [portRule]);

        // Expect NO semantic errors.
        // The `enforce_naming_pattern` lint would catch the missing 'Port' suffix.
        expect(lints, isEmpty);
      });

      test('Validates grammar on base name when suffix matches', () async {
        // Grammar: {{noun.phrase}}Port
        // Class: GetUserPort (Suffix matches, but "Get" is a verb -> Semantic Violation)
        final portRule = {'on': 'port', 'grammar': '{{noun.phrase}}Port'};

        const path = 'lib/features/user/domain/ports/get_user_port.dart';
        addFile(path, 'abstract interface class GetUserPort {}');

        final lints = await runLint(filePath: path, namingRules: [portRule]);

        expect(lints, hasLength(1));
        expect(lints.first.message, contains('implies an action/verb'));
      });
    });
  });
}
