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

    // Helper to write files safely using canonical paths
    void addFile(String relativePath, String content) {
      final fullPath = p.join(testProjectPath, p.normalize(relativePath));
      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_location_test_');
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

    Future<List<Diagnostic>> runLint({required String filePath}) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      // makeConfig uses default Naming Rules (Entity: {{name}}, Model: {{name}}Model, etc.)
      final config = makeConfig();
      final lint = EnforceFileAndFolderLocation(
        config: config,
        layerResolver: LayerResolver(config),
      );

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when a Model is found in an entities directory', () async {
      final path = 'lib/features/user/domain/entities/user_model.dart';
      // "UserModel" matches the Model pattern (specific) AND Entity pattern (generic).
      // The lint should catch this because Model is more specific.
      addFile(path, 'class UserModel {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('A Model was found in a "Entity" directory'));
    });

    test('reports violation when an Entity is found in a models directory', () async {
      final path = 'lib/features/user/data/models/user.dart';
      // "User" matches Entity pattern.
      addFile(path, 'class User {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('A Entity was found in a "Model" directory'));
    });

    test('does not report violation when a Model is in a models directory', () async {
      final path = 'lib/features/user/data/models/user_model.dart';
      addFile(path, 'class UserModel {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('does not report violation when an Entity is in an entities directory', () async {
      final path = 'lib/features/user/domain/entities/user.dart';
      addFile(path, 'class User {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('handles pattern collisions gracefully (e.g. Entity vs Usecase)', () async {
      // Both Entity and UseCase use {{name}}.
      // If we have a class named "Login" in 'usecases', it matches BOTH.
      // The lint should realize "Login" is valid for 'usecases' because the specificity is equal.
      final path = 'lib/features/auth/domain/usecases/login.dart';
      addFile(path, 'class Login {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('ignores files in non-architectural directories', () async {
      final path = 'lib/core/utils/helper.dart';
      addFile(path, 'class Helper {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}