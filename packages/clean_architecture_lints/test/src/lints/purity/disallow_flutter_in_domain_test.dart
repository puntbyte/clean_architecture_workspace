// test/src/lints/purity/disallow_flutter_in_domain_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/purity/disallow_flutter_in_domain.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowFlutterInDomain Lint', () {
    late PhysicalResourceProvider resourceProvider;
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = resourceProvider.getFile(normalizedPath);
      Directory(p.dirname(normalizedPath)).createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    Future<List<Diagnostic>> runLint(String filePath) async {
      final config = makeConfig();
      final lint = DisallowFlutterInDomain(config: config, layerResolver: LayerResolver(config));

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
      tempDir = Directory.systemTemp.createTempSync('flutter_in_domain_test_');
      projectPath = p.join(p.normalize(tempDir.path), 'test_project');
      final flutterPath = p.join(p.normalize(tempDir.path), 'flutter');

      // 1. Setup Project
      Directory(projectPath).createSync(recursive: true);
      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');

      // 2. Setup Fake Flutter Package
      // We create a fake 'flutter' package so the analyzer can resolve types from it.
      Directory(flutterPath).createSync(recursive: true);
      writeFile(p.join(flutterPath, 'pubspec.yaml'), 'name: flutter');
      // Create a fake material.dart with a Color class
      writeFile(p.join(flutterPath, 'lib', 'material.dart'), 'class Color {}');

      // 3. Configure Package Mapping
      // We point 'test_project' to itself and 'flutter' to our fake directory.
      final packageConfig =
          '''
      {
        "configVersion": 2,
        "packages": [
          {
            "name": "test_project",
            "rootUri": "../",
            "packageUri": "lib/"
          },
          {
            "name": "flutter",
            "rootUri": "${p.toUri(flutterPath)}",
            "packageUri": "lib/"
          }
        ]
      }
      ''';
      writeFile(p.join(projectPath, '.dart_tool', 'package_config.json'), packageConfig);

      contextCollection = AnalysisContextCollection(
        includedPaths: [projectPath],
        resourceProvider: resourceProvider,
      );
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should report violation for dart:ui import', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/entities/user.dart');
      writeFile(path, '''
        import 'dart:ui'; // VIOLATION
        class User {}
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
      expect(lints.first.diagnosticCode.name, 'disallow_flutter_in_domain');
    });

    test('should report violation for package:flutter import', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/entities/user.dart');
      writeFile(path, '''
        import 'package:flutter/material.dart'; // VIOLATION
        class User {}
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('should report violation for flutter types (e.g. Color)', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/entities/user.dart');
      // We use package:flutter here because we mocked it in setUp.
      // This allows the analyzer to resolve 'Color' and trigger the type check.
      writeFile(path, '''
        import 'package:flutter/material.dart';
        class User {
          final Color color; // VIOLATION (Type usage)
          User(this.color);
        }
      ''');

      final lints = await runLint(path);
      // Expect 2 lints:
      // 1. The import statement.
      // 2. The usage of `Color` in `final Color color`.
      expect(lints, hasLength(2));
    });

    test('should NOT report violation for pure Dart types', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/entities/user.dart');
      writeFile(path, '''
        class User {
          final String name;
          final int age;
          User(this.name, this.age);
        }
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });

    test('should NOT report violation if file is NOT in domain layer', () async {
      // This is in the Presentation layer, where Flutter IS allowed.
      final path = p.join(projectPath, 'lib/features/user/presentation/widgets/user_widget.dart');
      writeFile(path, '''
        import 'package:flutter/material.dart'; 
        class UserWidget {}
      ''');

      final lints = await runLint(path);
      expect(lints, isEmpty);
    });
  });
}
