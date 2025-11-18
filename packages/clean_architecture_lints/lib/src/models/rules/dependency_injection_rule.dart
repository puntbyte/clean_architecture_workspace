// lib/src/models/rules/dependency_injection_rule.dart

part of 'package:clean_architecture_lints/src/models/services_config.dart';

class DependencyInjectionRule {
  final List<String> serviceLocatorNames;

  const DependencyInjectionRule({
    required this.serviceLocatorNames,
  });

  factory DependencyInjectionRule.fromMap(Map<String, dynamic> map) {
    // This code is now correct because it receives the correct sub-map.
    return DependencyInjectionRule(
      serviceLocatorNames: map.asStringList('service_locator_names', orElse: ['getIt', 'locator', 'sl']),
    );
  }
}
