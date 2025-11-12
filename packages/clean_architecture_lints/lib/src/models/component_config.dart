// lib/src/models/component_config.dart

import 'package:clean_architecture_lints/src/analysis/component_kind.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

class ComponentConfig {
  final String key;
  final ComponentKind kind;
  final String label;
  final List<String> directories;
  final Map<String, ComponentConfig> subComponents;
  // THE FIX: Add a reference to the parent component.
  final ComponentConfig? parent;

  const ComponentConfig({
    required this.key,
    required this.kind,
    required this.label,
    required this.directories,
    required this.subComponents,
    this.parent, // Added to constructor
  });

  /// The top-level layer (e.g., domain_layer) that this component belongs to.
  ComponentConfig? get layer {
    var current = this;
    while (current.parent != null) {
      current = current.parent!;
    }
    return current;
  }

  factory ComponentConfig.fromMap(
      String key,
      Map<String, dynamic> map, {
        ComponentConfig? parent, // Accept parent during recursive parsing
      }) {
    final directoriesData = map['directory'];
    final directories = (directoriesData is String)
        ? [directoriesData]
        : (directoriesData is List ? directoriesData.whereType<String>().toList() : <String>[]);

    // Create the current component first, so we can pass it as the parent to its children.
    final component = ComponentConfig(
      key: key,
      kind: ComponentKind.fromString(map.getString('kind')),
      label: map.getString('label'),
      directories: directories,
      subComponents: {}, // Start with empty map
      parent: parent,
    );

    // Now, recursively parse all child components, passing `this` component as their parent.
    final subComponentsMap = map.getMap('components');
    component.subComponents.addAll(
      subComponentsMap.map(
            (subKey, subValue) => MapEntry(
          subKey,
          ComponentConfig.fromMap(subKey, subValue as Map<String, dynamic>, parent: component),
        ),
      ),
    );

    return component;
  }
}
