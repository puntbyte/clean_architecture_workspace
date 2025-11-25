// test/src/lints/naming/enforce_semantic_naming_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_semantic_naming.dart';
// Correct Import
import 'package:clean_architecture_lints/src/utils/nlp/language_analyzer.dart';
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
          'user': {'NOUN'},      // Singular
          'violation': {'NOUN'}, // Singular
          'violations': {'NOUN'}, // Plural logic might need dictionary, so we override here for test stability
          'list': {'NOUN'},
          // 'users' isn't needed if isNounPlural logic handles suffixes correctly,
          // but adding it for robust testing if dictionary is missing.
          'users': {'NOUN'},
        },
      );
    });

    tearDown(() {
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> namingRules,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit = await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(namingRules: namingRules);
      final lint = EnforceSemanticNaming(
        config: config,
        layerResolver: LayerResolver(config),
        analyzer: analyzer,
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    group('Plural Grammar: {{noun.plural}}', () {
      final listRule = {'on': 'model', 'grammar': '{{noun.plural}}List'};

      test('validates "UsersList" (Plural Noun)', () async {
        const path = 'lib/features/user/data/models/users_list.dart';
        addFile(path, 'class UsersList {}'); // "Users" -> "User" (Noun) -> Plural

        final lints = await runLint(filePath: path, namingRules: [listRule]);
        expect(lints, isEmpty);
      });

      test('reports violation for "UserList" (Singular Noun)', () async {
        const path = 'lib/features/user/data/models/user_list.dart';
        addFile(path, 'class UserList {}'); // "User" is singular

        final lints = await runLint(filePath: path, namingRules: [listRule]);
        expect(lints, hasLength(1));
        expect(lints.first.message, contains('must be a Plural Noun'));
      });
    });

    group('Singular Grammar: {{noun.singular}}', () {
      final entityRule = {'on': 'entity', 'grammar': '{{noun.singular}}'};

      test('validates "User" (Singular)', () async {
        const path = 'lib/features/user/domain/entities/user.dart';
        addFile(path, 'class User {}');
        final lints = await runLint(filePath: path, namingRules: [entityRule]);
        expect(lints, isEmpty);
      });

      test('reports violation for "Users" (Plural)', () async {
        const path = 'lib/features/user/domain/entities/users.dart';
        addFile(path, 'class Users {}');
        final lints = await runLint(filePath: path, namingRules: [entityRule]);
        expect(lints, hasLength(1));
        expect(lints.first.message, contains('must be a Singular Noun'));
      });
    });

    test('Port Example: TypeSafetyViolationsPort (Violations = Plural Noun)', () async {
      // Grammar is generic {{noun.phrase}}Port, which allows singular OR plural.
      // "Violations" ends in 's', stem "Violation" is Noun. So it is a Noun.
      final portRule = {'on': 'port', 'grammar': '{{noun.phrase}}Port'};

      const path = 'lib/features/user/domain/ports/violations_port.dart';
      addFile(path, 'abstract interface class TypeSafetyViolationsPort {}');

      final lints = await runLint(filePath: path, namingRules: [portRule]);
      expect(lints, isEmpty);
    });
  });
}
