// lib/src/models/dependency_injection_config.dart

import 'package:clean_architecture_kit/src/utils/extensions/json_map_extension.dart';

/// A strongly-typed representation of the `dependency_injection` block.
/// This now holds ALL DI-related configurations.
class DependencyInjectionConfig {
  /// The names of service locator functions to flag (e.g., 'getIt', 'locator').
  final List<String> serviceLocatorNames;

  const DependencyInjectionConfig({
    required this.serviceLocatorNames,
  });

  factory DependencyInjectionConfig.fromMap(Map<String, dynamic> map) {
    return DependencyInjectionConfig(
      serviceLocatorNames: map.getList('service_locator_names', ['getIt', 'locator', 'sl']),
    );
  }
}
