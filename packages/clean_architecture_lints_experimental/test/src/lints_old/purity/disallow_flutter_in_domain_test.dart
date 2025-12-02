// test/src/lints/purity/disallow_flutter_in_domain_test.dart

import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/purity/disallow_flutter_in_domain.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('DisallowFlutterInDomain Lint', () {
    late AnalysisContextCollection contextCollection;
    late Directory tempDir;
    late String projectPath;

    void writeFile(String path, String content) {
      final normalizedPath = p.normalize(path);
      final file = File(normalizedPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);
    }

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('flutter_in_domain_test_');
      projectPath = p.canonicalize(p.join(tempDir.path, 'test_project'));
      final flutterPath = p.canonicalize(p.join(tempDir.path, 'flutter'));

      // 1. Setup Project
      Directory(projectPath).createSync(recursive: true);
      writeFile(p.join(projectPath, 'pubspec.yaml'), 'name: test_project');

      // 2. Setup Fake Flutter Package
      Directory(flutterPath).createSync(recursive: true);
      writeFile(p.join(flutterPath, 'pubspec.yaml'), 'name: flutter');
      // Create a fake material.dart with a Color class
      writeFile(p.join(flutterPath, 'lib', 'material.dart'), 'class Color {}');

      // 3. Configure Package Mapping (Windows-safe URIs)
      final packageConfig = '''
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
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException catch (_) {
        // Ignore Windows file lock errors
      }
    });

    Future<List<Diagnostic>> runLint(String filePath) async {
      final fullPath = p.canonicalize(filePath);

      // Re-init context collection per test to ensure clean state
      contextCollection = AnalysisContextCollection(includedPaths: [projectPath]);

      final resolvedUnit = await contextCollection
          .contextFor(fullPath)
          .currentSession
          .getResolvedUnit(fullPath) as ResolvedUnitResult;

      final config = makeConfig();
      final lint = DisallowFlutterInDomain(config: config, layerResolver: LayerResolver(config));

      final lints = await lint.testRun(resolvedUnit);
      return lints.cast<Diagnostic>();
    }

    test('reports violation for dart:ui import', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/entities/user.dart');
      writeFile(path, '''
        import 'dart:ui'; // VIOLATION
        class User {}
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
      expect(lints.first.message, contains('Domain layer purity violation'));
    });

    test('reports violation for package:flutter import', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/entities/user.dart');
      writeFile(path, '''
        import 'package:flutter/material.dart'; // VIOLATION
        class User {}
      ''');

      final lints = await runLint(path);
      expect(lints, hasLength(1));
    });

    test('reports violation for flutter types (e.g. Color)', () async {
      final path = p.join(projectPath, 'lib/features/user/domain/entities/user.dart');
      // Uses explicit import AND type usage
      writeFile(path, '''
        import 'package:flutter/material.dart';
        class User {
          final Color color; // VIOLATION (Type usage)
          User(this.color);
        }
      ''');

      final lints = await runLint(path);
      // Expect 2 lints: 1 for import, 1 for type usage
      expect(lints, hasLength(2));
    });

    test('does not report violation for pure Dart types', () async {
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

    test('does not report violation if file is NOT in domain layer', () async {
      // Presentation layer allows Flutter
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