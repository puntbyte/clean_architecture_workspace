// test/src/lints/dependency/enforce_layer_independence_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/location/enforce_layer_independence.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('EnforceLayerIndependence Lint', () {
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
      required List<Map<String, dynamic>> locations,
    }) async {
      final config = makeConfig(locations: locations);
      final lint = EnforceLayerIndependence(config: config, layerResolver: LayerResolver(config));

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
      tempDir = Directory.systemTemp.createTempSync('layer_independence_test_');
      testProjectPath = p.join(p.normalize(tempDir.path), 'test_project');
      Directory(testProjectPath).createSync(recursive: true);

      writeFile(p.join(testProjectPath, 'pubspec.yaml'), 'name: test_project');
      writeFile(
        p.join(testProjectPath, '.dart_tool/package_config.json'),
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", '
        '"packageUri": "lib/"}]}',
      );

      writeFile(
        p.join(testProjectPath, 'lib/features/user/domain/entities/user.dart'),
        'class User {}',
      );
      writeFile(
        p.join(testProjectPath, 'lib/features/user/data/models/user_model.dart'),
        'class UserModel {}',
      );

      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation for a forbidden component import', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/usecases/get_user.dart');
      writeFile(path, "import 'package:test_project/features/user/data/models/user_model.dart';");

      final lints = await runLint(
        filePath: path,
        locations: [
          {
            'on': 'usecase',
            'forbidden': {'component': 'model'},
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_layer_independence_forbidden_component');
    });

    test('should report violation for a forbidden layer import', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/entities/user.dart');
      writeFile(path, "import 'package:test_project/features/user/data/models/user_model.dart';");

      final lints = await runLint(
        filePath: path,
        locations: [
          {
            'on': 'domain',
            'forbidden': {'component': 'data'},
          },
        ],
      );

      expect(lints, hasLength(1));
    });

    test('should report violation for a forbidden package import', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/entities/user.dart');
      writeFile(path, "import 'package:flutter/material.dart';");

      final lints = await runLint(
        filePath: path,
        locations: [
          {
            'on': 'domain',
            'forbidden': {'package': 'package:flutter/material.dart'},
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_layer_independence_forbidden_package');
    });

    test(
      'should report violation for an unallowed component when an allowed list exists',
      () async {
        final path = p.join(testProjectPath, 'lib/features/user/domain/usecases/get_user.dart');
        writeFile(path, "import 'package:test_project/features/user/data/models/user_model.dart';");

        final lints = await runLint(
          filePath: path,
          locations: [
            {
              'on': 'usecase',
              'allowed': {'component': 'entity'},
            },
          ],
        );

        expect(lints, hasLength(1));
        expect(lints.first.diagnosticCode.name, 'enforce_layer_independence_unallowed_component');
      },
    );

    test('should not report violation for an allowed component import', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/usecases/get_user.dart');
      writeFile(path, "import 'package:test_project/features/user/domain/entities/user.dart';");

      final lints = await runLint(
        filePath: path,
        locations: [
          {
            'on': 'usecase',
            'allowed': {'component': 'entity'},
          },
        ],
      );

      expect(lints, isEmpty);
    });

    test('should not report violation when no specific location rule applies', () async {
      final path = p.join(testProjectPath, 'lib/features/user/domain/usecases/get_user.dart');
      writeFile(path, "import 'package:test_project/features/user/data/models/user_model.dart';");

      final lints = await runLint(filePath: path, locations: []);

      expect(lints, isEmpty);
    });
  });
}
