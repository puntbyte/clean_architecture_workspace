import 'package:architecture_lints/src/configuration/component_config.dart';

class ProjectConfig {
  final Map<String, ComponentConfig> components;

  const ProjectConfig({
    required this.components,
  });

  ComponentConfig? findComponentForFile(String relativePath) {
    ComponentConfig? bestMatch;
    int maxSpecificity = -1;

    for (final component in components.values) {
      if (component.matchesPath(relativePath)) {
        // Calculate Specificity: Count the dots in the ID.
        // "domain" = 0 dots
        // "domain.entity" = 1 dot
        // "presentation.manager.bloc" = 2 dots
        final specificity = component.id.split('.').length;

        if (specificity > maxSpecificity) {
          maxSpecificity = specificity;
          bestMatch = component;
        }
      }
    }

    return bestMatch;
  }
}
