// test/src/lints/contract/enforce_repository_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_repository_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceRepositoryContract Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    void writeFile(String path, String content) {
      final file = resourceProvider.getFile(path);
      Directory(p.dirname(path)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint({
      required String filePath,
      String? contractDir = 'contracts', // Default directory for contracts
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final config = makeConfig(contractDir: contractDir, inheritances: inheritances);
      final lint = EnforceRepositoryContract(config: config, layerResolver: LayerResolver(config));

      final resolvedUnit =
          await contextCollection.contextFor(filePath).currentSession.getResolvedUnit(filePath)
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('repository_contract_test_');
      projectPath = p.join(tempDir.path, 'test_project');
      Directory(projectPath).createSync(recursive: true);

      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );
      writeFile(
        p.join(projectPath, 'lib', 'core', 'repository', 'repository.dart'),
        'abstract class Repository {}',
      );

      contextCollection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when repository contract does not extend Repository', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'user',
        'domain',
        'contracts',
        'user_repository.dart',
      );
      writeFile(path, 'abstract class UserRepository {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_repository_contract');
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'Repository interfaces must extend the base repository class `Repository`.',
      );
    });

    test(
      'should not report violation when repository contract correctly extends Repository',
      () async {
        final path = p.join(
          projectPath,
          'lib',
          'features',
          'order',
          'domain',
          'contracts',
          'order_repository.dart',
        );
        writeFile(path, '''
        import 'package:test_project/core/repository/repository.dart';
        abstract class OrderRepository extends Repository {}
      ''');

        final lints = await runLint(filePath: path);
        expect(lints, isEmpty);
      },
    );

    test('should not report violation for a concrete class in the contract layer', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'shared',
        'domain',
        'contracts',
        'concrete_repo.dart',
      );
      writeFile(path, 'class ConcreteRepo {}'); // Not abstract

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty, reason: 'Lint should only apply to abstract classes (interfaces).');
    });

    test('should be ignored when a custom inheritance rule for contracts is defined', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'custom',
        'domain',
        'contracts',
        'custom_repo.dart',
      );
      writeFile(path, 'abstract class CustomRepo {}');

      final lints = await runLint(
        filePath: path,
        inheritances: [
          {'on': 'contract'},
        ],
      );

      expect(lints, isEmpty, reason: 'Should defer to the generic enforce_inheritance lint.');
    });
  });
}
