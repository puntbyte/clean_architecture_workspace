import 'package:clean_architecture_kit/src/models/generation_options_config.dart';
import 'package:clean_architecture_kit/src/models/inheritance_config.dart';
import 'package:clean_architecture_kit/src/models/layer_config.dart';
import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:clean_architecture_kit/src/models/type_safety_config.dart';

Map<String, dynamic> _getMap(Map<String, dynamic> source, String key) {
  final value = source[key];
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

/// The main configuration class that parses the entire `architecture_kit` block
/// from the `analysis_options.yaml` file.
class CleanArchitectureConfig {
  final LayerConfig layers;
  final NamingConfig naming;
  final TypeSafetyConfig typeSafety;
  final InheritanceConfig inheritance;
  final GenerationOptionsConfig generation;

  const CleanArchitectureConfig({
    required this.layers,
    required this.naming,
    required this.typeSafety,
    required this.inheritance,
    required this.generation,
  });

  factory CleanArchitectureConfig.fromMap(Map<String, dynamic> map) {
    return CleanArchitectureConfig(
      // LayerConfig is smart enough to parse the top-level keys
      layers: LayerConfig.fromMap(map),
      // The other models expect their specific sub-maps
      naming: NamingConfig.fromMap(_getMap(map, 'naming_conventions')),
      typeSafety: TypeSafetyConfig.fromMap(_getMap(map, 'type_safety')),
      inheritance: InheritanceConfig.fromMap(_getMap(map, 'inheritance')),
      generation: GenerationOptionsConfig.fromMap(_getMap(map, 'generation_options')),
    );
  }
}
