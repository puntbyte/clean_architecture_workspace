// lib/src/lints/architecture_lint_rule.dart

import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// An abstract base class for all lints in the `clean_architecture_kit`.
///
/// This class provides common dependencies (`config`, `layerResolver`) to all subclasses,
/// reducing boilerplate and ensuring consistency.
abstract class CleanArchitectureLintRule extends DartLintRule {
  /// The parsed configuration from the user's `analysis_options.yaml`.
  final CleanArchitectureConfig config;

  /// A shared utility for resolving architectural layers from file paths.
  final LayerResolver layerResolver;

  const CleanArchitectureLintRule({
    required this.config,
    required this.layerResolver,
    required super.code,
  });
}
