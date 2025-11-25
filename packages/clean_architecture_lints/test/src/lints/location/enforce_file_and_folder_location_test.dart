import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/location/enforce_file_and_folder_location.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceFileAndFolderLocation Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('file_location_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');

      // Use a mapped package structure to ensure imports resolve correctly for inheritance checks
      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {"name": "example", "rootUri": "$libUri", "packageUri": "."}
        ]
      }
      ''');

      // Define base class for inheritance test
      addFile('lib/core/port.dart', 'abstract class Port {}');
    });

    tearDown(() {
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({required String filePath}) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      // We configure inheritance so the linter knows what a "Port" looks like
      final config = makeConfig(
          inheritances: [
            {'on': 'port', 'required': {'name': 'Port', 'import': 'package:example/core/port.dart'}}
          ]
      );

      final lint = EnforceFileAndFolderLocation(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when a Model is found in an entities directory', () async {
      final path = 'lib/features/user/domain/entities/user_model.dart';
      addFile(path, 'class UserModel {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('A Model was found in a "Entity" directory'));
    });

    test('reports violation when an Entity is found in a models directory', () async {
      final path = 'lib/features/user/data/models/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('A Entity was found in a "Model" directory'));
    });

    test('should NOT report violation if class implements the correct contract for its location', () async {
      // Scenario: 'AuthContract' matches Entity name pattern, but is in Port folder.
      // It implements Port, so location lint should accept it.

      final path = 'lib/features/auth/domain/ports/auth_contract.dart';
      addFile(path, '''
        import 'package:example/core/port.dart';
        abstract interface class AuthContract implements Port {} 
      ''');

      final lints = await runLint(filePath: path);

      expect(lints, isEmpty, reason: 'Inheritance check should override name-based guess');
    });

    test('handles pattern collisions gracefully', () async {
      final path = 'lib/features/auth/domain/usecases/login.dart';
      addFile(path, 'class Login {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}