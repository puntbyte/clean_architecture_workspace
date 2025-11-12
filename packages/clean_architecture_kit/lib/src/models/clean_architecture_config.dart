// lib/src/models/architecture_config.dart

import 'package:clean_architecture_kit/src/models/annotations_config.dart';
import 'package:clean_architecture_kit/src/models/inheritance_config.dart';
import 'package:clean_architecture_kit/src/models/layer_config.dart';
import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:clean_architecture_kit/src/models/services_config.dart';
import 'package:clean_architecture_kit/src/models/type_safety_config.dart';
import 'package:clean_architecture_kit/src/utils/extensions/json_map_extension.dart';

/// The main configuration class that parses the entire `architecture_kit` block from the
/// `analysis_options.yaml` file.
class CleanArchitectureConfig {
  final LayerConfig layers;
  final NamingConfig naming;
  final TypeSafetyConfig typeSafety;
  final InheritanceConfig inheritance;
  final ServicesConfig services;
  final AnnotationsConfig annotations;

  const CleanArchitectureConfig({
    required this.layers,
    required this.naming,
    required this.typeSafety,
    required this.inheritance,
    required this.services,
    required this.annotations,
  });

  factory CleanArchitectureConfig.fromMap(Map<String, dynamic> map) {
    return CleanArchitectureConfig(
      layers: LayerConfig.fromMap(map),
      naming: NamingConfig.fromMap(map.getMap('naming_conventions')),
      typeSafety: TypeSafetyConfig.fromMap(map.getMap('type_safety')),
      //inheritance: InheritanceConfig.fromMap(map.getMap('inheritance')),
      inheritance: InheritanceConfig.fromMap(map.getMap('inheritances')),
      services: ServicesConfig.fromMap(map.getMap('services')),
      annotations: AnnotationsConfig.fromMap(map.getMap('annotations')),
    );
  }
}
