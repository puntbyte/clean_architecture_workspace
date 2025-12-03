// lib/src/configuration/models/project_config.dart

import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/layer_config.dart';

/*class ProjectConfig {
  final Map<String, ComponentConfig> components;
  final List<LayerConfig> dependencies;

  const ProjectConfig({
    required this.components,
    this.dependencies = const [],
  });

  ComponentConfig? findComponentForFile(String relativePath) {
    ComponentConfig? bestMatch;
    var maxSpecificity = -1;

    for (final component in components.values) {
      if (component.matchesPath(relativePath)) {
        final specificity = component.id.split('.').length;
        if (specificity > maxSpecificity) {
          maxSpecificity = specificity;
          bestMatch = component;
        }
      }
    }

    return bestMatch;
  }
}*/
