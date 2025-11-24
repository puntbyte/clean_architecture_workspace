// test/src/lints/location/enforce_file_and_folder_location_test.dart

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

      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [{"name": "example", "rootUri": "$libUri", "packageUri": "."}]
      }
      ''');

      // Define base class for inheritance test
      addFile('lib/core/port/port.dart', 'abstract class Port {}');
    });

    tearDown(() {
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(inheritances: inheritances);
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

    test('should NOT report violation if class implements the correct contract for its location', () async {
      // Scenario: 'AuthContract' is in 'ports'.
      // Name 'AuthContract' matches Entity pattern "{{name}}" (Generic).
      // So Linter thinks it's an Entity.
      // BUT: It implements Port. The Linter should see this and suppress the Location error.

      final path = 'lib/features/auth/domain/ports/auth_contract.dart';
      addFile(path, '''
        import '../../../../core/port/port.dart';
        class AuthContract implements Port {} 
      ''');

      // Pass the inheritance config so the linter knows what a "Port" is
      final customInheritance = [
        {'on': 'port', 'required': {'name': 'Port', 'import': 'package:example/core/port/port.dart'}}
      ];

      final lints = await runLint(
        filePath: path,
        inheritances: customInheritance,
      );

      expect(lints, isEmpty, reason: 'Inheritance should prove intent overrides naming guess');
    });
  });
}