import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/config/detail/dependency_detail.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/dependency_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/boundaries/rules/component_dependency_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;
import 'package:pubspec_parse/pubspec_parse.dart';
import 'package:test/test.dart';

class TestLayerDependencyRule extends ComponentDependencyRule {
  final ArchitectureConfig mockConfig;

  const TestLayerDependencyRule(this.mockConfig);

  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    context.sharedState[ArchitectureConfig] = mockConfig;
    context.sharedState[FileResolver] = FileResolver(mockConfig);
    await super.startUp(resolver, context);
  }
}

void main() {
  group('LayerDependencyRule', () {
    late Directory tempDir;
    late String projectPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('layer_dep_test_');
      projectPath = p.canonicalize(tempDir.path);

      File(p.join(projectPath, 'pubspec.yaml')).writeAsStringSync('name: test_project');

      final libUri = p.toUri(p.join(projectPath, 'lib'));
      final pkgConfigFile = File(p.join(projectPath, '.dart_tool', 'package_config.json'));
      pkgConfigFile.parent.createSync(recursive: true);
      pkgConfigFile.writeAsStringSync('''
      {
        "configVersion": 2,
        "packages": [
          {"name": "test_project", "rootUri": "$libUri", "packageUri": "."}
        ]
      }
      ''');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<List<Diagnostic>> runLint({
      required String relativePath,
      required String content,
      required ArchitectureConfig config,
      List<Map<String, String>> extraFiles = const [],
    }) async {
      // 1. Create extra referenced files so imports resolve
      for (final file in extraFiles) {
        // FIX: Normalize path
        final fPath = p.normalize(p.join(projectPath, file['path']));
        final f = File(fPath);
        f.parent.createSync(recursive: true);
        f.writeAsStringSync(file['content']!);
      }

      // 2. Create target file
      // FIX: Normalize path
      final fullPath = p.normalize(p.join(projectPath, relativePath));

      final file = File(fullPath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(content);

      // 3. Resolve using real Analyzer Context
      final collection = AnalysisContextCollection(includedPaths: [projectPath]);
      final context = collection.contextFor(fullPath);
      final result = await context.currentSession.getResolvedUnit(fullPath);

      if (result is! ResolvedUnitResult) {
        throw StateError('Failed to resolve file: $fullPath');
      }

      final rule = TestLayerDependencyRule(config);
      return rule.testRun(result, pubspec: Pubspec('test_project'));
    }

    test('should report error when importing forbidden component', () async {
      final config = ArchitectureConfig(
        components: [
          const ComponentConfig(id: 'domain', paths: ['domain']),
          const ComponentConfig(id: 'data', paths: ['data']),
        ],
        dependencies: [
          DependencyConfig(
            onIds: const ['domain'],
            allowed: DependencyDetail.empty(),
            // Domain cannot import Data
            forbidden: const DependencyDetail(components: ['data']),
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/usecase.dart',
        content: "import '../../data/repo_impl.dart';\nclass UseCase {}",
        extraFiles: [
          {'path': 'lib/data/repo_impl.dart', 'content': 'class RepoImpl {}'},
        ],
      );

      expect(errors, hasLength(1));
      expect(errors.first.message, contains('cannot import "data"'));
    });

    test('should pass when importing allowed component', () async {
      final config = ArchitectureConfig(
        components: [
          const ComponentConfig(id: 'usecase', paths: ['domain/usecases']),
          const ComponentConfig(id: 'entity', paths: ['domain/entities']),
        ],
        dependencies: [
          DependencyConfig(
            onIds: const ['usecase'],
            // UseCase can import Entity
            allowed: const DependencyDetail(components: ['entity']),
            forbidden: DependencyDetail.empty(),
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/usecases/login.dart',
        content: "import '../entities/user.dart';\nclass Login {}",
        extraFiles: [
          {'path': 'lib/domain/entities/user.dart', 'content': 'class User {}'},
        ],
      );

      expect(errors, isEmpty);
    });

    test('should report error if component is not in allowed list (Strict Mode)', () async {
      final config = ArchitectureConfig(
        components: [
          const ComponentConfig(id: 'domain', paths: ['domain']),
          const ComponentConfig(id: 'presentation', paths: ['presentation']),
        ],
        dependencies: [
          DependencyConfig(
            onIds: const ['domain'],
            // Strict allow: Only allow self (domain)
            allowed: const DependencyDetail(components: ['domain']),
            forbidden: DependencyDetail.empty(),
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/logic.dart',
        content: "import '../presentation/widget.dart';\nclass Logic {}",
        extraFiles: [
          {'path': 'lib/presentation/widget.dart', 'content': 'class MyWidget {}'},
        ],
      );

      expect(errors, hasLength(1));
    });

    test('should allow importing from same component layer', () async {
      final config = ArchitectureConfig(
        components: [
          const ComponentConfig(id: 'domain', paths: ['domain']),
        ],
        dependencies: [
          DependencyConfig(
            onIds: const ['domain'],
            allowed: const DependencyDetail(components: ['domain']),
            forbidden: DependencyDetail.empty(),
          ),
        ],
      );

      final errors = await runLint(
        config: config,
        relativePath: 'lib/domain/a.dart',
        content: "import 'b.dart';\nclass A {}",
        extraFiles: [
          {'path': 'lib/domain/b.dart', 'content': 'class B {}'},
        ],
      );

      expect(errors, isEmpty);
    });
  });
}
