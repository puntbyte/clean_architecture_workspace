// lib/src/lints/architecture_lint_rule.dart

import 'package:clean_architecture_lints/src/analysis/component_resolver.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// An abstract base class for all lints in the `clean_architecture_kit`.
///
/// This class provides common dependencies (`config`, `layerResolver`) to all subclasses,
/// reducing boilerplate and ensuring consistency.
abstract class ArchitectureLintRule extends DartLintRule {
  /// The parsed configuration from the user's `analysis_options.yaml`.
  final ArchitectureConfig config;

  /// A shared utility for resolving architectural layers from file paths.
  final ComponentResolver componentResolver;

  const ArchitectureLintRule({
    required this.config,
    required this.componentResolver,
    required super.code,
  });
}
