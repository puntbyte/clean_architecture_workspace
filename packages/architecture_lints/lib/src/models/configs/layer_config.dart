// lib/src/models/configs/layer_config.dart

import 'package:architecture_lints/src/utils_old/config/config_keys.dart';
import 'package:architecture_lints/src/utils_old/extensions/json_map_extension.dart';

part '../rules/layer_rules.dart';

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
