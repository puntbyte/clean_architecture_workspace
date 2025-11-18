// lib/src/models/layer_config.dart

import 'package:clean_architecture_lints/src/utils/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'package:clean_architecture_lints/src/models/rules/domain_layer_rule.dart';
part 'package:clean_architecture_lints/src/models/rules/data_layer_rule.dart';
part 'package:clean_architecture_lints/src/models/rules/presentation_layer_rule.dart';

/// The parent configuration class for all layer and path definitions.
class LayerConfig {
  final DomainLayerRule domain;
  final DataLayerRule data;
  final PresentationLayerRule presentation;

  const LayerConfig({
    required this.domain,
    required this.data,
    required this.presentation,
  });

  factory LayerConfig.fromMap(Map<String, dynamic> map) {
    return LayerConfig(
      domain: DomainLayerRule.fromMap(map.asMap(ConfigKey.module.domain)),
      data: DataLayerRule.fromMap(map.asMap(ConfigKey.module.data)),
      presentation: PresentationLayerRule.fromMap(map.asMap(ConfigKey.module.presentation)),
    );
  }
}
