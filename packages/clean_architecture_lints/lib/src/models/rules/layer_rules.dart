// lib/src/models/rules/inheritance_rule.dart

part of 'package:clean_architecture_lints/src/models/layer_config.dart';

class DomainLayerRule {
  final List<String> entity;
  final List<String> usecase;
  final List<String> port;

  const DomainLayerRule({required this.entity, required this.usecase, required this.port});

  factory DomainLayerRule.fromMap(Map<String, dynamic> map) {
    return DomainLayerRule(
      entity: map.asStringList(ConfigKey.layer.entity, orElse: [ConfigKey.layer.entityDir]),
      usecase: map.asStringList(ConfigKey.layer.usecase, orElse: [ConfigKey.layer.usecaseDir]),
      port: map.asStringList(ConfigKey.layer.port, orElse: [ConfigKey.layer.portDir]),
    );
  }
}

class DataLayerRule {
  final List<String> model;
  final List<String> repository;
  final List<String> source;

  const DataLayerRule({required this.model, required this.repository, required this.source});

  factory DataLayerRule.fromMap(Map<String, dynamic> map) {
    return DataLayerRule(
      model: map.asStringList(ConfigKey.layer.model, orElse: [ConfigKey.layer.modelDir]),
      repository: map.asStringList(
        ConfigKey.layer.repository,
        orElse: [ConfigKey.layer.repositoryDir],
      ),
      source: map.asStringList(ConfigKey.layer.source, orElse: [ConfigKey.layer.sourceDir]),
    );
  }
}

class PresentationLayerRule {
  final List<String> page;
  final List<String> widget;
  final List<String> manager;

  const PresentationLayerRule({required this.page, required this.widget, required this.manager});

  factory PresentationLayerRule.fromMap(Map<String, dynamic> map) {
    return PresentationLayerRule(
      manager: map.asStringList(ConfigKey.layer.manager, orElse: [ConfigKey.layer.managerDir]),
      page: map.asStringList(ConfigKey.layer.page, orElse: [ConfigKey.layer.pageDir]),
      widget: map.asStringList(ConfigKey.layer.widget, orElse: [ConfigKey.layer.widgetDir]),
    );
  }
}
