import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/type_safety/enforce_type_safety.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('EnforceTypeSafety Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('type_safety_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');
      addFile('.dart_tool/package_config.json', '{"configVersion": 2, "packages": []}');
      addFile('lib/core/types.dart', 'class IntId {} class FutureEither<T> {}');
      addFile('lib/features/user/data/models/user_model.dart', 'class UserModel {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> typeSafeties,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(typeSafeties: typeSafeties);
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('Parameter Violation: int parameter named "id" should be IntId', () async {
      const path = 'lib/features/user/domain/ports/auth_port.dart';
      addFile(path, '''
        abstract interface class AuthPort {
          void getUser(int id); // VIOLATION
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeSafeties: [
          {
            'on': ['port'],
            'parameters': [
              {'unsafe_type': 'int', 'identifier': 'id', 'safe_type': 'IntId'},
            ],
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('parameter `id` should be of type `IntId`, not `int`'));
    });

    test('Return Violation: Future should be FutureEither', () async {
      const path = 'lib/features/user/domain/ports/auth_port.dart';
      addFile(path, '''
        abstract interface class AuthPort {
          Future<void> logout(); // VIOLATION
        }
      ''');

      final lints = await runLint(
        filePath: path,
        typeSafeties: [
          {
            'on': ['port'],
            'returns': {'unsafe_type': 'Future', 'safe_type': 'FutureEither'},
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('return type should be `FutureEither`, not `Future`'));
    });
  });
}
