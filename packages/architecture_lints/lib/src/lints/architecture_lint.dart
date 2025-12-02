// lib/src/lints/architecture_lint.dart

import 'package:architecture_lints/src/configuration/component_config.dart';
import 'package:architecture_lints/src/configuration/config_loader.dart';
import 'package:architecture_lints/src/configuration/project_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class ArchitectureLint extends DartLintRule {
  const ArchitectureLint({required super.code});

  @override
  Future<void> startUp(
      CustomLintResolver resolver,
      CustomLintContext context,
      ) async {
    await super.startUp(resolver, context);

    // 1. Resolve the project root
    final result = await resolver.getResolvedUnitResult();
    final rootPath = result.session.analysisContext.contextRoot.root.path;

    // 2. Load the config (ConfigLoader handles caching internally)
    await ConfigLoader.load(rootPath);
  }

  ProjectConfig? getConfig() {
    return ConfigLoader.getCachedConfig();
  }

  ComponentConfig? getComponentFromFile(ProjectConfig config, String path) {
    return config.findComponentForFile(path);
  }
}
