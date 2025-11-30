// lib/src/models/details/type_safety_detail.dart

part of '../configs/type_safeties_config.dart';

/// Represents a specific type safety requirement.
class TypeSafetyDetail {
  final String? kind; // 'return' or 'parameter'
  final String? definition; // Reference to type_definitions (e.g. 'result.wrapper')
  final String? type; // Raw type name (e.g. 'Future')
  final String? import; // Import URI
  final String? component; // Architectural Component
  final String? identifier; // Parameter name

  const TypeSafetyDetail({
    this.kind,
    this.definition,
    this.type,
    this.import,
    this.component,
    this.identifier,
  });

  factory TypeSafetyDetail.fromMap(Map<String, dynamic> map) {
    return TypeSafetyDetail(
      kind: map.asStringOrNull(ConfigKey.rule.kind),
      definition: map.asStringOrNull(ConfigKey.rule.definition),
      type: map.asStringOrNull(ConfigKey.rule.type),
      import: map.asStringOrNull(ConfigKey.rule.import),
      component: map.asStringOrNull(ConfigKey.rule.component),
      identifier: map.asStringOrNull(ConfigKey.rule.identifier),
    );
  }
}
