import 'package:clean_architecture_kit/src/models/generation_options_config.dart';
import 'package:clean_architecture_kit/src/models/inheritance_config.dart';
import 'package:clean_architecture_kit/src/models/layer_config.dart';
import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:clean_architecture_kit/src/models/type_safety_config.dart';
import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';

/// The main configuration class that parses the entire `architecture_kit` block from the
/// `analysis_options.yaml` file.
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
      layers: LayerConfig.fromMap(map),
      naming: NamingConfig.fromMap(map.getMap('naming_conventions')),
      typeSafety: TypeSafetyConfig.fromMap(map.getMap('type_safety')),
      inheritance: InheritanceConfig.fromMap(map.getMap('inheritance')),
      generation: GenerationOptionsConfig.fromMap(map.getMap('generation_options')),
    );
  }
}
