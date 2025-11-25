// lib/src/models/rules/service_locator_rule.dart

part of '../services_config.dart';

class ServiceLocatorRule {
  final List<String> names;
  final String? import; // Added support for 'import'

  const ServiceLocatorRule({
    required this.names,
    this.import,
  });

  factory ServiceLocatorRule.fromMap(Map<String, dynamic> map) {
    return ServiceLocatorRule(
      names: map.asStringList(ConfigKey.service.locatorNames, orElse: ['getIt', 'locator', 'sl']),
      import: map.asStringOrNull(ConfigKey.rule.import),
    );
  }
}
