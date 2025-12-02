// lib/src/models/configs/services_config.dart

import 'package:architecture_lints/src/utils_old/config/config_keys.dart';
import 'package:architecture_lints/src/utils_old/extensions/json_map_extension.dart';

part '../rules/service_locator_rule.dart';

class ServicesConfig {
  final ServiceLocatorRule serviceLocator;

  const ServicesConfig({
    required this.serviceLocator,
  });

  factory ServicesConfig.fromMap(Map<String, dynamic> map) {
    return ServicesConfig(
      serviceLocator: ServiceLocatorRule.fromMap(
        map.asMap(ConfigKey.root.services).asMap(ConfigKey.service.serviceLocator),
      ),
    );
  }
}
