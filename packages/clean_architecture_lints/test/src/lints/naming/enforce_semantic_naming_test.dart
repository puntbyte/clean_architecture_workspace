// test/src/lints/naming/enforce_semantic_naming_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_semantic_naming.dart';
import 'package:clean_architecture_lints/src/utils/nlp/natural_language_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceSemanticNaming Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String testProjectPath;
    late NaturalLanguageUtils nlpUtils;

    // Helper to write files safely using canonical paths
    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      // [Windows Fix] Use canonical path
      tempDir = Directory.systemTemp.createTempSync('semantic_naming_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      // Create a deterministic NLP utility for tests.
      nlpUtils = NaturalLanguageUtils(
        posOverrides: {
          'get': {'VERB'},
          'fetch': {'VERB'},
          'user': {'NOUN'},
          'profile': {'NOUN'},
          'loading': {'NOUN', 'ADJ'}, // Loading can be used as state
          'loaded': {'VERB', 'ADJ'},
          'initial': {'ADJ'},
        },
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
      final lint = EnforceSemanticNaming(
        config: config,
        layerResolver: LayerResolver(config),
        nlpUtils: nlpUtils,
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    group('Usecase Grammar: {{verb.present}}{{noun.phrase}}', () {
      final usecaseRule = {'on': 'usecase', 'grammar': '{{verb.present}}{{noun.phrase}}'};

      test('should not report violation for a valid Verb+Noun name', () async {
        final path = 'lib/features/user/domain/usecases/get_user.dart';
        addFile(path, 'class GetUser {}');
        final lints = await runLint(filePath: path, namingRules: [usecaseRule]);
        expect(lints, isEmpty);
      });

      test('should report violation for a Noun+Verb name', () async {
        final path = 'lib/features/user/domain/usecases/user_get.dart';
        addFile(path, 'class UserGet {}');
        final lints = await runLint(filePath: path, namingRules: [usecaseRule]);
        expect(lints, hasLength(1));
      });
    });

    group('Model Grammar: {{noun.phrase}}Model', () {
      final modelRule = {'on': 'model', 'grammar': '{{noun.phrase}}Model'};

      test('should not report violation for a valid Noun+Suffix name', () async {
        final path = 'lib/features/user/data/models/user_profile_model.dart';
        addFile(path, 'class UserProfileModel {}');
        final lints = await runLint(filePath: path, namingRules: [modelRule]);
        expect(lints, isEmpty);
      });

      test('should report violation when phrase before suffix contains a verb', () async {
        final path = 'lib/features/user/data/models/fetch_user_model.dart';
        addFile(path, 'class FetchUserModel {}'); // "Fetch" is a verb
        final lints = await runLint(filePath: path, namingRules: [modelRule]);
        expect(lints, hasLength(1));
      });
    });

    group('State Grammar: {{subject}}({{adjective}}|{{verb.gerund}}|{{verb.past}})', () {
      final stateRule = {
        'on': 'state.implementation',
        'grammar': '{{subject}}({{adjective}}|{{verb.gerund}}|{{verb.past}})',
      };

      test('should not report violation for a valid State name (Adjective)', () async {
        // Ensure path is recognized as state implementation by LayerResolver
        final path = 'lib/features/auth/presentation/managers/auth_state.dart';
        addFile(path, 'class AuthInitial {}');

        final lints = await runLint(filePath: path, namingRules: [stateRule]);
        expect(lints, isEmpty);
      });

      test('should not report violation for a valid State name (Gerund)', () async {
        final path = 'lib/features/auth/presentation/managers/auth_state.dart';
        addFile(path, 'class AuthLoading {}');
        final lints = await runLint(filePath: path, namingRules: [stateRule]);
        expect(lints, isEmpty);
      });
    });

    test('should be silent when a rule has no grammar property', () async {
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, 'class GetUser {}');

      // Rule has a pattern but no grammar.
      final lints = await runLint(
        filePath: path,
        namingRules: [
          {'on': 'usecase', 'pattern': '{{name}}'},
        ],
      );

      expect(lints, isEmpty);
    });
  });
}