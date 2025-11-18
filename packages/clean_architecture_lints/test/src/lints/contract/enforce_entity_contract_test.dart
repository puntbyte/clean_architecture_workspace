// test/src/lints/contract/enforce_entity_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_entity_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceEntityContract Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    // A robust helper that creates parent directories before writing.
    void writeFile(String path, String content) {
      final file = resourceProvider.getFile(path);
      Directory(p.dirname(path)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint(
      String filePath, {
      String? entityDir = 'entities',
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final config = makeConfig(entityDir: entityDir, inheritances: inheritances);
      final lint = EnforceEntityContract(config: config, layerResolver: LayerResolver(config));

      final resolvedUnit =
          await contextCollection.contextFor(filePath).currentSession.getResolvedUnit(filePath)
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('entity_contract_test_');
      projectPath = p.join(tempDir.path, 'test_project');
      Directory(projectPath).createSync(recursive: true);

      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );
      writeFile(
        p.join(projectPath, 'lib', 'core', 'entity', 'entity.dart'),
        'abstract class Entity {}',
      );

      contextCollection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when a concrete class does not extend Entity', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'product',
        'domain',
        'entities',
        'product.dart',
      );
      writeFile(path, 'class Product {}');

      final lints = await runLint(path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_entity_contract');
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'Entities must extend the base entity class `Entity`.',
      );
    });

    test('should not report violation when class correctly extends Entity', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'order',
        'domain',
        'entities',
        'order.dart',
      );
      writeFile(path, '''
        import 'package:test_project/core/entity/entity.dart';
        class Order extends Entity {}
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should not report violation for an abstract class', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'shared',
        'domain',
        'entities',
        'base_entity.dart',
      );
      writeFile(path, 'abstract class BaseEntity {}');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should be ignored when a custom inheritance rule for entities is defined', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'custom',
        'domain',
        'entities',
        'custom.dart',
      );
      writeFile(path, 'class Custom {}');

      final lints = await runLint(
        path,
        inheritances: [
          {'on': 'entity'},
        ],
      );

      expect(lints, isEmpty, reason: 'Should defer to the generic enforce_inheritance lint.');
    });
  });
}
