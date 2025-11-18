// lib/src/models/rules/presentation_layer_rule.dart

part of 'package:clean_architecture_lints/src/models/layer_config.dart';

/// Represents the configuration for the domain layer directories.
class DomainLayerRule {
  final List<String> entity;
  final List<String> contract;
  final List<String> usecase;

  const DomainLayerRule({
    required this.entity,
    required this.contract,
    required this.usecase,
  });

  factory DomainLayerRule.fromMap(Map<String, dynamic> map) {
    return DomainLayerRule(
      entity: map.asStringList(ConfigKey.layer.entity, orElse: [ConfigKey.layer.entityDir]),
      contract: map.asStringList(ConfigKey.layer.contract, orElse: [ConfigKey.layer.contractDir]),
      usecase: map.asStringList(ConfigKey.layer.usecase, orElse: [ConfigKey.layer.usecaseDir]),
    );
  }
}
