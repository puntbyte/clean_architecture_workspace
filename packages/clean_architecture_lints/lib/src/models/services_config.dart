import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'rules/service_locator_rule.dart';

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
