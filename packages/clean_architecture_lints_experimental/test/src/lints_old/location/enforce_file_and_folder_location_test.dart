import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/location/enforce_file_and_folder_location.dart';
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
        "packages": [
          {"name": "example", "rootUri": "$libUri", "packageUri": "."},
          {"name": "clean_architecture_core", "rootUri": "../", "packageUri": "lib/"}
        ]
      }
      ''');

      addFile('lib/core/port.dart', 'abstract class Port {}');
    });

    tearDown(() {
      try { tempDir.deleteSync(recursive: true); } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? inheritances,
      List<Map<String, dynamic>>? namingRules,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(
        inheritances: inheritances,
        namingRules: namingRules,
      );

      final lint = EnforceFileAndFolderLocation(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('Does NOT report violation for UserDTO in models (Valid Inheritance)', () async {
      // Scenario:
      // 1. Inheritance Rule: Model must extend Entity.
      // 2. Naming Rules: Entity={{name}}, Model={{name}}Model.
      // 3. File: 'UserDTO' in models/.
      // 4. Structural: 'UserDTO' extends 'User'. 'User' is in entities/.
      // Result: Location should be valid because it satisfies the inheritance rule.

      final inheritances = [
        {'on': 'model', 'required': {'component': 'entity'}}
      ];

      final namingRules = [
        {'on': 'entity', 'pattern': '{{name}}'},
        {'on': 'model', 'pattern': '{{name}}Model'},
      ];

      // 1. Create the Entity
      addFile('lib/features/user/domain/entities/user.dart', 'class User {}');

      // 2. Create the Model
      final path = 'lib/features/user/data/models/user_dto.dart';
      // Use relative import so analyzer resolves 'User' as an Entity
      addFile(path, '''
        import '../../domain/entities/user.dart';
        class UserDTO extends User {}
      ''');

      final lints = await runLint(
        filePath: path,
        inheritances: inheritances,
        namingRules: namingRules,
      );

      expect(lints, isEmpty, reason: 'UserDTO extends User (Entity), so it is valid in Models');
    });

    test('Reports violation for UserDTO in models if it does NOT extend Entity', () async {
      // Same setup, but UserDTO does not extend User.
      // It matches Entity name pattern {{name}}, but is in Model folder.
      // Should fail.

      final inheritances = [
        {'on': 'model', 'required': {'component': 'entity'}}
      ];
      final namingRules = [
        {'on': 'entity', 'pattern': '{{name}}'},
        {'on': 'model', 'pattern': '{{name}}Model'},
      ];

      // Create Entity
      addFile('lib/features/user/domain/entities/user.dart', 'class User {}');

      final path = 'lib/features/user/data/models/user_dto.dart';
      addFile(path, '''
        class UserDTO {} // Does NOT extend User
      ''');

      final lints = await runLint(
        filePath: path,
        inheritances: inheritances,
        namingRules: namingRules,
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('A Entity was found in a "Model" directory'));
    });
  });
}