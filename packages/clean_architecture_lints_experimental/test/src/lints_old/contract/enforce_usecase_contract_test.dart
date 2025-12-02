// test/src/lints/contract/enforce_usecase_contract_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/contract/enforce_usecase_contract.dart';
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

      // Define core use cases
      addFile('lib/core/usecase/usecase.dart', '''
        abstract class UnaryUsecase {} 
        abstract class NullaryUsecase {}
      ''');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
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
      final lint = EnforceUsecaseContract(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('Default Rule: reports violation when use case does not extend base', () async {
      const path = 'lib/features/auth/domain/usecases/login.dart';
      addFile(path, 'class Login {}');

      final lints = await runLint(filePath: path);

      expect(lints, hasLength(1));
      expect(
        lints.first.message,
        contains('UseCases must extend one of the base use case classes'),
      );
    });

    test('Default Rule: Valid when extending UnaryUsecase (Local)', () async {
      const path = 'lib/features/order/domain/usecases/create_order.dart';
      addFile(path, '''
        import '../../../../core/usecase/usecase.dart';
        class CreateOrder extends UnaryUsecase {}
      ''');

      final lints = await runLint(filePath: path);
      expect(lints, isEmpty);
    });

    test('Custom Rule: Valid when extending Configured Base (Template Match)', () async {
      // Config says 'package:example/...'
      final customConfig = [
        {
          'on': 'usecase',
          'required': [
            {'name': 'UnaryUsecase', 'import': 'package:example/core/usecase/usecase.dart'},
          ],
        },
      ];

      const path = 'lib/features/custom/domain/usecases/custom.dart';
      // Code uses relative import (resolves to same file on disk)
      addFile(path, '''
        import '../../../../core/usecase/usecase.dart';
        class CustomUseCase extends UnaryUsecase {}
      ''');

      final lints = await runLint(
        filePath: path,
        inheritances: customConfig,
      );

      expect(lints, isEmpty);
    });

    test('Custom Rule: Reports violation if extending wrong class', () async {
      final customConfig = [
        {
          'on': 'usecase',
          'required': [
            {'name': 'UnaryUsecase', 'import': 'package:example/core/usecase/usecase.dart'},
          ],
        },
      ];

      const path = 'lib/features/custom/domain/usecases/custom.dart';
      addFile(path, '''
        class CustomUseCase {}
      ''');

      final lints = await runLint(
        filePath: path,
        inheritances: customConfig,
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('UnaryUsecase'));
    });
  });
}
