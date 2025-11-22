import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_usecase_contract.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceUsecaseContract Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('usecase_contract_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
            '"packageUri": "lib/"}]}',
      );
      addFile(
        'lib/core/usecase/usecase.dart',
        'abstract class UnaryUsecase {} abstract class NullaryUsecase {}',
      );
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
      String? usecaseDir = 'usecases',
      List<Map<String, dynamic>>? inheritances,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;

      final config = makeConfig(usecaseDir: usecaseDir, inheritances: inheritances);
      final lint = EnforceUsecaseContract(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation when use case does not extend a base use case', () async {
      const path = 'lib/features/auth/domain/usecases/login.dart';
      addFile(path, 'class Login {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      // FIX: Updated string expectation to match "use case" (two words)
      expect(
        lints.first.message,
        contains('UseCases must extend one of the base use case classes'),
      );
    });

    test('does not report violation when use case extends UnaryUsecase', () async {
      const path = 'lib/features/order/domain/usecases/create_order.dart';
      addFile(path, '''
        import 'package:test_project/core/usecase/usecase.dart';
        class CreateOrder extends UnaryUsecase {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('does not report violation when use case extends NullaryUsecase', () async {
      const path = 'lib/features/product/domain/usecases/get_products.dart';
      addFile(path, '''
        import 'package:test_project/core/usecase/usecase.dart';
        class GetProducts extends NullaryUsecase {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('ignores abstract use case classes', () async {
      const path = 'lib/features/shared/domain/usecases/base_usecase.dart';
      addFile(path, 'abstract class BaseUsecase {}');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('skips itself when custom inheritance rule is defined', () async {
      const path = 'lib/features/custom/domain/usecases/custom.dart';
      addFile(path, 'class CustomUseCase {}');

      final lints = await runLint(
        filePath: path,
        inheritances: [
          {
            'on': 'usecase',
            'required': {'name': 'MyCustomBase', 'import': 'pkg:x'},
          },
        ],
      );

      expect(lints, isEmpty, reason: 'Should disable itself in favor of custom rule');
    });
  });
}
