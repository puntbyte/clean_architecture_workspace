// lib/src/models/services_config.dart

import 'package:clean_architecture_kit/src/models/dependency_injection_config.dart';
import 'package:clean_architecture_kit/src/utils/extensions/json_map_extension.dart';

/// The parent configuration class for all service-related rules.
class ServicesConfig {
  final DependencyInjectionConfig dependencyInjection;

  const ServicesConfig({
    required this.dependencyInjection,
  });

  factory ServicesConfig.fromMap(Map<String, dynamic> map) {
    return ServicesConfig(
      dependencyInjection: DependencyInjectionConfig.fromMap(map.getMap('dependency_injection')),
    );
  }
}
