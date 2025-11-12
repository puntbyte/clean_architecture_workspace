// lib/src/models/architecture_config.dart

// Import the new model.
// ... other imports

// You can now DELETE the old `layer_config.dart` file.

import 'package:clean_architecture_lints/src/models/annotations_config.dart';
import 'package:clean_architecture_lints/src/models/component_config.dart';
import 'package:clean_architecture_lints/src/models/inheritance_config.dart';
import 'package:clean_architecture_lints/src/models/naming_config.dart';
import 'package:clean_architecture_lints/src/models/services_config.dart';
import 'package:clean_architecture_lints/src/models/type_safety_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

class ArchitectureConfig {
  // --- OLD PROPERTIES REMOVED ---
  // final LayerConfig layers;

  // --- NEW, SIMPLIFIED PROPERTY ---
  /// The root of the architectural component tree, parsed from the `components` block.
  final Map<String, ComponentConfig> components;

  final NamingConfig naming;
  final TypeSafetyConfig typeSafety;
  final InheritanceConfig inheritance;
  final AnnotationsConfig annotations;
  final ServicesConfig services;

  const ArchitectureConfig({
    required this.components, // Updated
    required this.naming,
    required this.typeSafety,
    required this.inheritance,
    required this.annotations,
    required this.services,
  });

  factory ArchitectureConfig.fromMap(Map<String, dynamic> map) {
    // Parse the top-level `components` map from YAML.
    final componentsMap = map.getMap('components');
    final components = componentsMap.map(
          (key, value) => MapEntry(
        key,
        // The `fromMap` factory no longer takes a parent, as these are the top-level nodes.
        ComponentConfig.fromMap(key, value as Map<String, dynamic>),
      ),
    );

    return ArchitectureConfig(
      components: components, // Updated
      naming: NamingConfig.fromMap(map.getMap('naming_conventions')),
      typeSafety: TypeSafetyConfig.fromMap(map.getMap('type_safeties')),
      inheritance: InheritanceConfig.fromMap(map),
      annotations: AnnotationsConfig.fromMap(map.getMap('annotations')),
      services: ServicesConfig.fromMap(map.getMap('services')),
    );
  }
}
