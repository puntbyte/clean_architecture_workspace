// test/src/lints/dependency/enforce_layer_independence_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/dependency/enforce_layer_independence.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import '../../../helpers/test_data.dart';

void main() {
  group('EnforceLayerIndependence Lint', () {
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
      tempDir = Directory.systemTemp.createTempSync('layer_indep_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: example');

      final libUri = p.toUri(p.join(testProjectPath, 'lib'));
      addFile('.dart_tool/package_config.json', '''
      {
        "configVersion": 2,
        "packages": [
          {"name": "example", "rootUri": "$libUri", "packageUri": "."}
        ]
      }
      ''');

      addFile('lib/features/user/domain/entities/user.dart', 'class User {}');
      addFile('lib/features/user/data/models/user_model.dart', 'class UserModel {}');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    Future<List<Diagnostic>> runLint({
      required String filePath,
      required List<Map<String, dynamic>> dependencies,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);
      final resolvedUnit =
          await contextCollection.contextFor(fullPath).currentSession.getResolvedUnit(fullPath)
              as ResolvedUnitResult;
      final config = makeConfig(dependencies: dependencies);
      final lint = EnforceLayerIndependence(config: config, layerResolver: LayerResolver(config));
      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('Violates Layer Rule: Domain entity imports Flutter', () async {
      const path = 'lib/features/user/domain/entities/user.dart';
      addFile(path, "import 'package:flutter/material.dart';");

      final lints = await runLint(
        filePath: path,
        dependencies: [
          {
            'on': 'domain',
            'forbidden': {'package': 'package:flutter/'},
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_layer_independence');
      expect(lints.first.message, contains('must not import the package `package:flutter/`'));
    });

    test('Violates Component Rule: Entity imports Model', () async {
      const path = 'lib/features/user/domain/entities/user.dart';
      addFile(path, "import 'package:example/features/user/data/models/user_model.dart';");

      final lints = await runLint(
        filePath: path,
        dependencies: [
          {
            'on': 'entity',
            'allowed': {
              'component': ['entity'],
            },
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_layer_independence');
      expect(lints.first.message, contains('not allowed to import from a Model'));
    });

    test('Violates Layer Rule: Domain imports Data (Model)', () async {
      const path = 'lib/features/user/domain/entities/user.dart';
      addFile(path, "import 'package:example/features/user/data/models/user_model.dart';");

      final lints = await runLint(
        filePath: path,
        dependencies: [
          {
            'on': 'domain',
            'forbidden': {'component': 'data'},
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'enforce_layer_independence');
      expect(lints.first.message, contains('must not import from a Model'));
    });
  });
}
