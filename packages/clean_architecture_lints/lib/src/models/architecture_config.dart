// lib/src/models/architecture_config.dart

import 'package:clean_architecture_lints/src/models/annotations_config.dart';
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:clean_architecture_lints/src/models/layer_config.dart';
import 'package:clean_architecture_lints/src/models/locations_config.dart';
import 'package:clean_architecture_lints/src/models/module_config.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/models/services_config.dart';
import 'package:clean_architecture_lints/src/models/type_safeties_config.dart';
import 'package:clean_architecture_lints/src/utils/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// The main configuration class that parses the entire configuration from
/// `analysis_options.yaml`.
class ArchitectureConfig {
  final ModuleConfig module;
  final LayerConfig layer;
  final InheritancesConfig inheritances;
  final NamingConventionsConfig namingConventions;
  final TypeSafetiesConfig typeSafeties;
  final LocationsConfig locations;
  final AnnotationsConfig annotations;
  final ServicesConfig services;

  const ArchitectureConfig({
    required this.module,
    required this.layer,
    required this.inheritances,
    required this.namingConventions,
    required this.typeSafeties,
    required this.locations,
    required this.annotations,
    required this.services,
  });

  /// Creates an instance from a configuration map.
  /// Missing sections will result in default configurations.
  factory ArchitectureConfig.fromMap(Map<String, dynamic> map) {
    return ArchitectureConfig(
      module: ModuleConfig.fromMap(map.asMap(ConfigKey.root.modules)),
      layer: LayerConfig.fromMap(map.asMap(ConfigKey.root.layers)),
      inheritances: InheritancesConfig.fromMap(map),
      namingConventions: NamingConventionsConfig.fromMap(map),
      typeSafeties: TypeSafetiesConfig.fromMap(map),
      locations: LocationsConfig.fromMap(map),
      annotations: AnnotationsConfig.fromMap(map),
      services: ServicesConfig.fromMap(map.asMap(ConfigKey.root.services)),
    );
  }
}
