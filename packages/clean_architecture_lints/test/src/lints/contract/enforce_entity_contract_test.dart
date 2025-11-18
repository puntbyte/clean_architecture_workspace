// test/srcs/lints/contract/enforce_entity_contract_test.dart

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
    late String testProjectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint({
      required String filePath,
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final config = makeConfig(inheritances: inheritances);
      final lint = EnforceEntityContract(config: config, layerResolver: LayerResolver(config));

      final resolvedUnit =
          await contextCollection
                  .contextFor(p.normalize(filePath))
                  .currentSession
                  .getResolvedUnit(p.normalize(filePath))
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('entity_contract_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(testProjectPath, '.dart_tool/package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      writeFile(p.join(testProjectPath, 'lib/core/entity/entity.dart'), 'abstract class Entity {}');
      writeFile(
        p.join(testProjectPath, 'lib/domain/my_base_entity.dart'),
        'abstract class MyBaseEntity {}',
      );

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    group('when using default contract', () {
      test('should report violation when a concrete entity does not extend Entity', () async {
        final path = p.join(testProjectPath, 'lib/features/product/domain/entities/product.dart');
        writeFile(path, 'class Product {}');

        final lints = await runLint(filePath: path);

        expect(lints, hasLength(1));
        // FIX: Call the getter `lintName` instead of referencing the function.
        expect(lints.first.diagnosticCode.name, EnforceEntityContractMeta.lintName);
        expect(
          lints.first.problemMessage.messageText(includeUrl: false),
          EnforceEntityContractMeta.problemMessageFor('Entity'),
        );
      });

      test('should not report violation when an entity correctly extends Entity', () async {
        final path = p.join(testProjectPath, 'lib/features/order/domain/entities/order.dart');
        writeFile(path, '''
          import 'package:test_project/core/entity/entity.dart';
          class Order extends Entity {}
        ''');

        final lints = await runLint(filePath: path);
        expect(lints, isEmpty);
      });
    });

    group('when using custom inheritance rule', () {
      final customRule = {
        'on': 'entity',
        'required': {
          'name': 'MyBaseEntity',
          'import': 'package:test_project/domain/my_base_entity.dart',
        },
      };

      test('should report violation when entity does not extend the custom base class', () async {
        final path = p.join(testProjectPath, 'lib/features/product/domain/entities/product.dart');
        writeFile(path, 'class Product {}');

        final lints = await runLint(filePath: path, inheritances: [customRule]);

        expect(lints, hasLength(1));
        // FIX: Ensure the expected string does not have backticks.
        expect(
          lints.first.problemMessage.messageText(includeUrl: false),
          'Entities must extend or implement one of: MyBaseEntity.',
        );
      });

      test('should report violation when entity extends the wrong (default) base class', () async {
        final path = p.join(testProjectPath, 'lib/features/product/domain/entities/product.dart');
        writeFile(path, '''
          import 'package:test_project/core/entity/entity.dart';
          class Product extends Entity {}
        ''');

        final lints = await runLint(filePath: path, inheritances: [customRule]);

        expect(
          lints,
          hasLength(1),
          reason: 'A custom rule is active, so the default Entity is no longer valid.',
        );
        // FIX: Ensure the expected string does not have backticks.
        expect(
          lints.first.problemMessage.messageText(includeUrl: false),
          'Entities must extend or implement one of: MyBaseEntity.',
        );
      });

      test(
        'should not report violation when entity correctly extends the custom base class',
        () async {
          final path = p.join(testProjectPath, 'lib/features/product/domain/entities/product.dart');
          writeFile(path, '''
          import 'package:test_project/domain/my_base_entity.dart';
          class Product extends MyBaseEntity {}
        ''');

          final lints = await runLint(filePath: path, inheritances: [customRule]);
          expect(lints, isEmpty);
        },
      );
    });

    test('should not report violation for an abstract entity class', () async {
      final path = p.join(testProjectPath, 'lib/features/shared/domain/entities/base_entity.dart');
      writeFile(path, 'abstract class BaseEntity {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });
  });
}
