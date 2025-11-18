// lib/src/models/rules/presentation_layer_rule.dart

part of 'package:clean_architecture_lints/src/models/layer_config.dart';

/// Represents the configuration for the data layer directories.
class DataLayerRule {
  final List<String> model;
  final List<String> repository;
  final List<String> source;

  const DataLayerRule({
    required this.model,
    required this.repository,
    required this.source,
  });

  factory DataLayerRule.fromMap(Map<String, dynamic> map) {
    return DataLayerRule(
      model: map.asStringList(ConfigKey.layer.model, orElse: [ConfigKey.layer.modelDir]),
      repository: map.asStringList(ConfigKey.layer.repository, orElse: [ConfigKey.layer.repositoryDir]),
      source: map.asStringList(ConfigKey.layer.source, orElse: [ConfigKey.layer.sourceDir]),
    );
  }
}
