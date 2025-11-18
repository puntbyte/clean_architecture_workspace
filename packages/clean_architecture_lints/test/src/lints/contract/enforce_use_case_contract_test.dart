// test/src/lints/contracts/enforce_use_case_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_use_case_contract.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/test_data.dart';
import '../../../helpers/test_lint_runner.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeToken());
    registerFallbackValue(FakeLintCode());
  });

  group('EnforceUseCaseContract Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectLib;

    void writeFile(String path, String content) {
      final file = resourceProvider.getFile(path);
      file.parent.create();
      file.writeAsStringSync(content);
    }

    setUpAll(() {
      resourceProvider = PhysicalResourceProvider.INSTANCE;
      tempDir = Directory.systemTemp.createTempSync('usecase_contract_test_');
      final projectPath = p.join(tempDir.path, 'test_project');
      projectLib = p.join(projectPath, 'lib');

      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(projectPath, '.dart_tool', 'package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );
      writeFile(
        p.join(projectLib, 'core', 'usecase', 'usecase.dart'),
        '''
        abstract class UnaryUsecase {}
        abstract class NullaryUsecase {}
        ''',
      );

      contextCollection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDownAll(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should report violation when use case does not extend base use case', () async {
      final config = makeConfig(usecaseDir: 'usecases');
      final lint = EnforceUseCaseContract(config: config, layerResolver: LayerResolver(config));
      final path = p.join(projectLib, 'features', 'auth', 'domain', 'usecases', 'login.dart');
      const source = 'class Login {}';
      writeFile(path, source);

      final capturedCodes = await runContractLint(
        source: source,
        path: path,
        lint: lint,
        contextCollection: contextCollection,
      );

      expect(capturedCodes, hasLength(1), reason: 'Should detect missing UseCase inheritance');
      expect(
        capturedCodes.first.problemMessage,
        contains('must implement one of the base use case classes'),
      );
    });

    test('should not report violation when use case extends UnaryUsecase', () async {
      final config = makeConfig(usecaseDir: 'usecases');
      final lint = EnforceUseCaseContract(config: config, layerResolver: LayerResolver(config));
      final path = p.join(
        projectLib,
        'features',
        'order',
        'domain',
        'usecases',
        'create_order.dart',
      );
      const source = '''
        import 'package:test_project/core/usecase/usecase.dart';
        class CreateOrder extends UnaryUsecase {}
      ''';
      writeFile(path, source);

      final capturedCodes = await runContractLint(
        source: source,
        path: path,
        lint: lint,
        contextCollection: contextCollection,
      );

      expect(capturedCodes, isEmpty, reason: 'Should allow UnaryUsecase inheritance');
    });

    test('should not report violation when use case extends NullaryUsecase', () async {
      final config = makeConfig(usecaseDir: 'usecases');
      final lint = EnforceUseCaseContract(config: config, layerResolver: LayerResolver(config));
      final path = p.join(
        projectLib,
        'features',
        'product',
        'domain',
        'usecases',
        'get_products.dart',
      );
      const source = '''
        import 'package:test_project/core/usecase/usecase.dart';
        class GetProducts extends NullaryUsecase {}
      ''';
      writeFile(path, source);

      final capturedCodes = await runContractLint(
        source: source,
        path: path,
        lint: lint,
        contextCollection: contextCollection,
      );

      expect(capturedCodes, isEmpty, reason: 'Should allow NullaryUsecase inheritance');
    });

    test('should not report violation for abstract use case classes', () async {
      final config = makeConfig(usecaseDir: 'usecases');
      final lint = EnforceUseCaseContract(config: config, layerResolver: LayerResolver(config));
      final path = p.join(
        projectLib,
        'features',
        'shared',
        'domain',
        'usecases',
        'base_usecase.dart',
      );
      const source = 'abstract class BaseUsecase {}';
      writeFile(path, source);

      final capturedCodes = await runContractLint(
        source: source,
        path: path,
        lint: lint,
        contextCollection: contextCollection,
      );

      expect(capturedCodes, isEmpty, reason: 'Should skip abstract classes');
    });

    test('should stay silent when a custom inheritance rule is defined', () async {
      final config = makeConfig(
        usecaseDir: 'usecases',
        inheritanceRules: [
          {'on': 'usecase'},
        ],
      );
      final lint = EnforceUseCaseContract(config: config, layerResolver: LayerResolver(config));
      final path = p.join(projectLib, 'features', 'custom', 'domain', 'usecases', 'custom.dart');
      const source = 'class CustomUseCase {}';
      writeFile(path, source);

      final capturedCodes = await runContractLint(
        source: source,
        path: path,
        lint: lint,
        contextCollection: contextCollection,
      );

      expect(
        capturedCodes,
        isEmpty,
        reason: 'Should defer to the generic enforce_inheritance lint',
      );
    });
  });
}
