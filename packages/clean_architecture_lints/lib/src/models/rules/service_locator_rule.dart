// lib/src/models/rules/service_locator_rule.dart

part of '../configs/services_config.dart';

class ServiceLocatorRule {
  final List<String> names;
  final String? import;

  const ServiceLocatorRule({
    required this.names,
    this.import,
  });

  factory ServiceLocatorRule.fromMap(Map<String, dynamic> map) {
    return ServiceLocatorRule(
      // FIX: Added 'GetIt' (class) and 'Injector' to defaults
      names: map.asStringList(
        ConfigKey.service.locatorNames,
        orElse: ['getIt', 'GetIt', 'locator', 'sl', 'Injector'],
      ),
      import: map.asStringOrNull(ConfigKey.rule.import),
    );
  }
}
