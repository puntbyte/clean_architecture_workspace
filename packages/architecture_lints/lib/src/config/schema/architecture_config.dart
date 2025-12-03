import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';

class ArchitectureConfig {
  final List<ComponentConfig> components;

  const ArchitectureConfig({required this.components});

  factory ArchitectureConfig.empty() => const ArchitectureConfig(components: []);

  factory ArchitectureConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    final rawComponents = yaml[ConfigKeys.root.components];

    // STRICT CHECK:
    // If 'components' is defined but is NOT a Map (e.g. it's a List), throw an error.
    // This ensures we don't silently ignore bad configuration.
    if (rawComponents != null && rawComponents is! Map) {
      throw FormatException(
        "Invalid configuration: '${ConfigKeys.root.components}' must be a Map, "
        'but found ${rawComponents.runtimeType}.',
      );
    }

    // Now it's safe to cast or use getMap knowing it's either null or Map
    final componentsMap = yaml.getMap(ConfigKeys.root.components);
    final components = <ComponentConfig>[];

    componentsMap.forEach((key, value) {
      if (value is Map) {
        components.add(ComponentConfig.fromMap(key, value));
      }
    });

    return ArchitectureConfig(components: components);
  }
}
