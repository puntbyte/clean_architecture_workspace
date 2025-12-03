// lib/src/configuration/models/layer_config.dart

class LayerConfig {
  /// The component IDs this rule applies to (e.g. ['domain', 'domain.entity'])
  final List<String> onLayers;

  /// Whitelist rules
  final DependencyRule? allowed;

  /// Blacklist rules
  final DependencyRule? forbidden;

  const LayerConfig({
    required this.onLayers,
    this.allowed,
    this.forbidden,
  });
}

class DependencyRule {
  /// List of component IDs (e.g. ['data', 'presentation'])
  final List<String> components;

  /// List of import patterns (e.g. ['package:flutter/**', 'dart:io'])
  final List<String> imports;

  const DependencyRule({
    this.components = const [],
    this.imports = const [],
  });

  bool get isEmpty => components.isEmpty && imports.isEmpty;
}
