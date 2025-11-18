// lib/src/models/rules/presentation_layer_rule.dart

part of 'package:clean_architecture_lints/src/models/layer_config.dart';

/// Represents the configuration for the presentation layer directories.
class PresentationLayerRule {
  final List<String> page;
  final List<String> widget;
  final List<String> manager;

  const PresentationLayerRule({
    required this.page,
    required this.widget,
    required this.manager,
  });

  factory PresentationLayerRule.fromMap(Map<String, dynamic> map) {
    return PresentationLayerRule(
      manager: map.asStringList(ConfigKey.layer.manager, orElse: [ConfigKey.layer.managerDir]),
      page: map.asStringList(ConfigKey.layer.page, orElse: [ConfigKey.layer.pageDir]),
      widget: map.asStringList(ConfigKey.layer.widget, orElse: [ConfigKey.layer.widgetDir]),
    );
  }
}
