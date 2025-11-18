// test/src/lints/contract/enforce_use_case_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_use_case_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceUseCaseContract Lint', () {
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
      String? usecaseDir = 'usecases',
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final config = makeConfig(usecaseDir: usecaseDir, inheritances: inheritances);
      final lint = EnforceUseCaseContract(config: config, layerResolver: LayerResolver(config));

      final resolvedUnit =
          await contextCollection.contextFor(filePath).currentSession.getResolvedUnit(filePath)
              as ResolvedUnitResult;

      return lint.testRun(resolvedUnit);
    }

    setUp(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('usecase_contract_test_');
      projectPath = p.join(tempDir.path, 'test_project');
      Directory(projectPath).createSync(recursive: true);

      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
        '"packageUri": "lib/"}]}',
      );
      writeFile(
        p.join(projectPath, 'lib', 'core', 'usecase', 'usecase.dart'),
        'abstract class UnaryUsecase {} abstract class NullaryUsecase {}',
      );

      contextCollection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation when use case does not extend a base use case', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'auth',
        'domain',
        'usecases',
        'login.dart',
      );
      writeFile(path, 'class Login {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_use_case_contract');
      expect(
        lints.first.problemMessage.messageText(includeUrl: false),
        'UseCases must extend one of the base use case classes: UnaryUsecase or NullaryUsecase.',
      );
    });

    test('should not report violation when use case extends UnaryUsecase', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'order',
        'domain',
        'usecases',
        'create_order.dart',
      );
      writeFile(path, '''
        import 'package:test_project/core/usecase/usecase.dart';
        class CreateOrder extends UnaryUsecase {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('should not report violation when use case extends NullaryUsecase', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'product',
        'domain',
        'usecases',
        'get_products.dart',
      );
      writeFile(path, '''
        import 'package:test_project/core/usecase/usecase.dart';
        class GetProducts extends NullaryUsecase {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('should not report violation for an abstract use case class', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'shared',
        'domain',
        'usecases',
        'base_usecase.dart',
      );
      writeFile(path, 'abstract class BaseUsecase {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty, reason: 'Lint should only apply to concrete classes.');
    });

    test('should be ignored when a custom inheritance rule for use cases is defined', () async {
      final path = p.join(
        projectPath,
        'lib',
        'features',
        'custom',
        'domain',
        'usecases',
        'custom.dart',
      );
      writeFile(path, 'class CustomUseCase {}');

      final lints = await runLint(
        filePath: path,
        inheritances: [
          {'on': 'usecase'},
        ],
      );

      expect(lints, isEmpty, reason: 'Should defer to the generic enforce_inheritance lint.');
    });
  });
}
