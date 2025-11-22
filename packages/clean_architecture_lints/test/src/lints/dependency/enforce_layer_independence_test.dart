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
      tempDir = Directory.systemTemp.createTempSync('layer_independence_test_');
      testProjectPath = p.canonicalize(tempDir.path);

      addFile('pubspec.yaml', 'name: test_project');
      addFile(
        '.dart_tool/package_config.json',
        '{"configVersion": 2, "packages": [{"name": "test_project", "rootUri": "../", "packageUri": "lib/"}]}',
      );

      // Setup strict file structure for LayerResolver
      addFile('lib/features/user/domain/entities/user.dart', 'class User {}');
      addFile('lib/features/user/data/models/user_model.dart', 'class UserModel {}');
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
      required List<Map<String, dynamic>> dependencies,
    }) async {
      final fullPath = p.canonicalize(p.join(testProjectPath, filePath));
      contextCollection = AnalysisContextCollection(includedPaths: [testProjectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig(dependencies: dependencies);
      final lint = EnforceLayerIndependence(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation for a forbidden component import', () async {
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      // Usecase (Domain) imports Model (Data)
      addFile(path, "import 'package:test_project/features/user/data/models/user_model.dart';");

      final lints = await runLint(
        filePath: path,
        dependencies: [
          {
            'on': 'usecase',
            'forbidden': {'component': 'model'},
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('must not import from a Model'));
    });

    test('reports violation for a forbidden layer import', () async {
      final path = 'lib/features/user/domain/entities/user.dart';
      // Entity (Domain) imports Model (Data)
      addFile(path, "import 'package:test_project/features/user/data/models/user_model.dart';");

      final lints = await runLint(
        filePath: path,
        dependencies: [
          {
            'on': 'domain', // Layer-level rule
            'forbidden': {'component': 'data'}, // Forbid entire data layer
          },
        ],
      );

      expect(lints, hasLength(1));
      // FIX: The imported file is a Model. The linter reports the specific component name ("Model"),
      // even though it was caught by a layer-wide rule ("Data").
      expect(lints.first.message, contains('must not import from a Model'));
    });

    test('reports violation for a forbidden external package import', () async {
      final path = 'lib/features/user/domain/entities/user.dart';
      addFile(path, "import 'package:flutter/material.dart';");

      final lints = await runLint(
        filePath: path,
        dependencies: [
          {
            'on': 'domain',
            'forbidden': {'package': 'package:flutter'},
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('must not import the package `package:flutter`'));
    });

    test('reports violation for an unallowed component import (Whitelist Mode)', () async {
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, "import 'package:test_project/features/user/data/models/user_model.dart';");

      final lints = await runLint(
        filePath: path,
        dependencies: [
          {
            'on': 'usecase',
            'allowed': {'component': 'entity'}, // Only entities allowed
          },
        ],
      );

      expect(lints, hasLength(1));
      expect(lints.first.message, contains('is not allowed to import from a Model'));
    });

    test('does not report violation for an allowed component import', () async {
      final path = 'lib/features/user/domain/usecases/get_user.dart';
      addFile(path, "import 'package:test_project/features/user/domain/entities/user.dart';");

      final lints = await runLint(
        filePath: path,
        dependencies: [
          {
            'on': 'usecase',
            'allowed': {'component': 'entity'},
          },
        ],
      );

      expect(lints, isEmpty);
    });
  });
}