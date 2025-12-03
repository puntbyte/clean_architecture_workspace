import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:architecture_lints/src/configuration/parsing/config_loader.dart';
import 'package:architecture_lints/src/lints/naming/antipattern_naming_lint.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../utils/architecture_config_mock.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    ConfigLoader.reset();
    tempDir = await Directory.systemTemp.createTemp('antipattern_lint_test');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<List<String>> runLint({
    required String yamlContent,
    required String filePath,
    required String fileContent,
  }) async {
    final rootPath = p.normalize(p.absolute(tempDir.path));

    File(p.join(rootPath, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment: sdk: '>=3.0.0 <4.0.0'
''');

    File(p.join(rootPath, 'architecture.yaml')).writeAsStringSync(yamlContent);

    final sourcePath = p.normalize(p.absolute(p.join(rootPath, filePath)));
    File(sourcePath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(fileContent);

    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final context = collection.contextFor(sourcePath);
    final result = await context.currentSession.getResolvedUnit(sourcePath);

    if (result is! ResolvedUnitResult) {
      throw Exception('Failed to resolve file: $result');
    }

    await ConfigLoader.loadX(result.session.analysisContext.contextRoot.root.path);

    // Run Antipattern Lint
    final lint = const AntipatternNamingLint();
    final errors = await lint.testRun(result);

    return errors.map((e) => e.diagnosticCode.name).toList();
  }

  group('AntipatternNamingLint', () {
    test('should NOT report errors when class name is clean (matches nothing)', () async {
      final yaml = ArchitectureConfigMock()
          .addComponent(
        'domain.entity',
        path: 'lib/domain/entities',
        antipattern: '{{name}}Entity',
      )
          .toYaml();

      final errors = await runLint(
        yamlContent: yaml,
        filePath: 'lib/domain/entities/user.dart',
        fileContent: 'class User {}',
      );

      expect(errors, isEmpty);
    });

    test('should report arch_antipattern_naming when class name matches forbidden pattern', () async {
      final yaml = ArchitectureConfigMock()
          .addComponent(
        'domain.entity',
        path: 'lib/domain/entities',
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

    test('should ignore components without an antipattern defined', () async {
      final yaml = ArchitectureConfigMock()
          .addComponent(
        'domain.value',
        path: 'lib/domain/values',
        // No antipattern
      )
          .toYaml();

      final errors = await runLint(
        yamlContent: yaml,
        filePath: 'lib/domain/values/money_value.dart',
        fileContent: 'class MoneyValue {}',
      );

      expect(errors, isEmpty);
    });
  });
}