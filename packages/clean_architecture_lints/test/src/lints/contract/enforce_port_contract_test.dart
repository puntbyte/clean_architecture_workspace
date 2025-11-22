// test/src/lints/contract/enforce_port_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_port_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforcePortContract Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('port_contract_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );

      // Create the local core repository definition to simulate the base contract
      addFile('lib/core/repository/repository.dart', 'abstract class Repository {}');
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
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(inheritances: inheritances);
      final lint = EnforcePortContract(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when Port interface does not extend Repository', () async {
      // By default, files in 'domain/ports' are considered Ports
      const path = 'lib/features/user/domain/ports/user_repository.dart';
      addFile(path, '''
        abstract class UserRepository {}
      ''');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(
        lints.first.message,
        contains('Port interfaces must extend the base repository class `Repository`'),
      );
    });

    test('reports no violation when extending local Repository', () async {
      const path = 'lib/features/user/domain/ports/user_repository.dart';
      addFile(path, '''
        import 'package:test_project/core/repository/repository.dart';
        abstract class UserRepository extends Repository {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('ignores concrete classes (implementations)', () async {
      // EnforcePortContract only cares about abstract interfaces
      const path = 'lib/features/user/domain/ports/concrete_user_repo.dart';
      addFile(path, '''
        class ConcreteUserRepo {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('DISABLES itself when a custom inheritance rule for Port is defined', () async {
      // We define a custom rule for 'port'.
      // Even though UserRepository violates the *default* rule (it doesn't extend Repository),
      // this lint should return empty because it disabled itself.
      // (The EnforceCustomInheritance lint would handle this file instead).

      final customConfig = [
        {
          'on': 'port',
          'required': {'name': 'CustomBase', 'import': 'pkg:x'},
        },
      ];

      const path = 'lib/features/user/domain/ports/user_repository.dart';
      addFile(path, 'abstract class UserRepository {}');

      final lints = await runLint(
        filePath: path,
        inheritances: customConfig,
      );

      expect(lints, isEmpty, reason: 'Lint should disable itself when custom rule is present');
    });
  });
}
