import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart'; // <--- NEW
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart'; // <--- NEW
import 'package:architecture_lints/src/configuration/config_loader.dart';
import 'package:architecture_lints/src/lints/naming/class_naming_lint.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../utils/architecture_config_mock.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    ConfigLoader.reset();
    tempDir = await Directory.systemTemp.createTemp('arch_lint_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<List<String>> runLint({
    required String yamlContent,
    required String filePath,
    required String fileContent,
  }) async {
    // 0. Normalize the root path once
    final rootPath = p.normalize(p.absolute(tempDir.path));

    // 1. Write pubspec.yaml
    final pubspecFile = File(p.join(rootPath, 'pubspec.yaml'));
    await pubspecFile.writeAsString('''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
''');

    // 2. Write architecture.yaml
    final yamlFile = File(p.join(rootPath, 'architecture.yaml'));
    await yamlFile.writeAsString(yamlContent);

    // 3. Write source file
    final sourcePath = p.normalize(p.absolute(p.join(rootPath, filePath)));
    final sourceFile = File(sourcePath);
    await sourceFile.parent.create(recursive: true);
    await sourceFile.writeAsString(fileContent);

    // 4. Resolve using AnalysisContextCollection (The Fix)
    // This forces the analyzer to treat 'rootPath' as the included directory,
    // guaranteeing that contextRoot.root.path equals rootPath.
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );

    final context = collection.contextFor(sourcePath);
    final someResult = await context.currentSession.getResolvedUnit(sourcePath);

    if (someResult is! ResolvedUnitResult) {
      throw Exception('Failed to resolve file. Result type: ${someResult.runtimeType}');
    }
    final result = someResult;

    // 5. DEBUG: Verify Config Loading
    final detectedRoot = result.session.analysisContext.contextRoot.root.path;
    await ConfigLoader.load(detectedRoot);

    if (ConfigLoader.getCachedConfig() == null) {
      throw Exception(
          'TEST SETUP ERROR: ConfigLoader failed. \nReason: ${ConfigLoader.loadError}\nDetected Root: $detectedRoot\nExpected Root: $rootPath');
    }

    // 6. Run Lint
    final lint = const ClassNamingLint();
    final errors = await lint.testRun(result);

    return errors.map((e) => e.diagnosticCode.name).toList();
  }

  group('ClassNamingLint', () {
    test('should report no errors when class name matches the pattern', () async {
      final yaml = ArchitectureConfigMock()
          .addComponent(
        'domain.repository',
        path: 'lib/domain/repositories',
        pattern: '{{name}}Repository',
      )
          .toYaml();

      final errors = await runLint(
        yamlContent: yaml,
        filePath: 'lib/domain/repositories/auth_repository.dart',
        fileContent: 'class AuthRepository {}',
      );

      expect(errors, isEmpty);
    });

    test('should report arch_class_naming when class name does NOT match pattern', () async {
      final yaml = ArchitectureConfigMock()
          .addComponent(
        'domain.repository',
        path: 'lib/domain/repositories',
        pattern: '{{name}}Repository',
      )
          .toYaml();

      final errors = await runLint(
        yamlContent: yaml,
        filePath: 'lib/domain/repositories/auth_service.dart',
        fileContent: 'class AuthService {}',
      );

      expect(errors, contains('arch_class_naming'));
    });

    test('should report arch_antipattern_naming when class name matches antipattern', () async {
      final yaml = ArchitectureConfigMock()
          .addComponent(
        'domain.entity',
        path: 'lib/domain/entities',
        pattern: '{{name}}',
        antipattern: '{{name}}Entity',
      )
          .toYaml();

      final errors = await runLint(
        yamlContent: yaml,
        filePath: 'lib/domain/entities/user_entity.dart',
        fileContent: 'class UserEntity {}',
      );

      expect(errors, contains('arch_antipattern_naming'));
    });

    test('should ignore files that do not belong to any component (Orphans)', () async {
      final yaml = ArchitectureConfigMock()
          .addComponent(
        'domain.entity',
        path: 'lib/domain/entities',
        pattern: '{{name}}',
      )
          .toYaml();

      final errors = await runLint(
        yamlContent: yaml,
        filePath: 'lib/random/whatever.dart',
        fileContent: 'class RandomClass {}',
      );

      expect(errors, isEmpty);
    });
  });
}