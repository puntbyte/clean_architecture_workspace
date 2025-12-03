// lib/src/models/configs/module_config.dart

import 'package:architecture_lints/src/utils/config/config_keys_old.dart';
import 'package:architecture_lints/src/utils/extensions/json_map_extension.dart';

/// Strongly-typed representation of the `module_definitions` configuration block.
class ModuleConfig {
  final ModuleType type;
  final String core;
  final String features;
  final String domain;
  final String data;
  final String presentation;

  const ModuleConfig({
    required this.type,
    required this.core,
    required this.features,
    required this.domain,
    required this.data,
    required this.presentation,
  });

  /// Creates a ModuleConfig from a map, using defaults for missing values.
  factory ModuleConfig.fromMap(Map<String, dynamic> map) {
    final layers = map.asMap(ConfigKey.module.layers);

    return ModuleConfig(
      type: _parseType(map),
      core: map.asString(ConfigKey.module.core, orElse: ConfigKey.module.coreDir),
      features: map.asString(ConfigKey.module.features, orElse: ConfigKey.module.featuresDir),
      domain: layers.asString(ConfigKey.module.domain, orElse: ConfigKey.module.domainDir),
      data: layers.asString(ConfigKey.module.data, orElse: ConfigKey.module.dataDir),
      presentation: layers.asString(
        ConfigKey.module.presentation,
        orElse: ConfigKey.module.presentationDir,
      ),
    );
  }

  /// Parses the module type from the map, defaulting to featureFirst.
  static ModuleType _parseType(Map<String, dynamic> map) {
    final typeText = map.asString(ConfigKey.module.type, orElse: ModuleType.featureFirst.name);
    return ModuleType.fromString(typeText);
  }
}

/// Defines the project structure strategy with type-safe parsing.
enum ModuleType {
  layerFirst('layer_first'),
  featureFirst('feature_first'),
  unknown('unknown')
  ;

  final String name;

  const ModuleType(this.name);

  /// Parses a string into a ModuleType, defaulting to unknown if invalid.
  static ModuleType fromString(String value) => ModuleType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => ModuleType.unknown,
  );
}
