// lib/src/models/services_config.dart

import 'package:clean_architecture_lints/src/utils/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'package:clean_architecture_lints/src/models/rules/dependency_injection_rule.dart';

class ServicesConfig {
  final DependencyInjectionRule dependencyInjection;

  const ServicesConfig({
    required this.dependencyInjection,
  });

  factory ServicesConfig.fromMap(Map<String, dynamic> map) {
    return ServicesConfig(
      dependencyInjection: DependencyInjectionRule.fromMap(
        map.asMap(ConfigKey.root.services).asMap(ConfigKey.service.dependencyInjection),
      ),
    );
  }
}
