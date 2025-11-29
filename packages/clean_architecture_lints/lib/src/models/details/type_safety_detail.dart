// lib/src/models/details/type_safety_detail.dart

part of '../configs/type_safeties_config.dart';

/// Represents a specific type safety requirement.
/// Can target a specific type name, a type definition key, or an architectural component.
class TypeSafetyDetail {
  final String? kind; // 'return' or 'parameter'
  final String? type; // Raw type name ('int') or TypeDefinition key ('result.wrapper')
  final String? component; // Architectural component ('model', 'entity')
  final String? identifier; // Parameter name (only for kind: 'parameter')

  const TypeSafetyDetail({
    this.kind,
    this.type,
    this.component,
    this.identifier,
  });

  factory TypeSafetyDetail.fromMap(Map<String, dynamic> map) {
    return TypeSafetyDetail(
      kind: map.asStringOrNull(ConfigKey.rule.kind),
      type: map.asStringOrNull(ConfigKey.rule.type), // Unified 'type' key
      component: map.asStringOrNull(ConfigKey.rule.component),
      identifier: map.asStringOrNull(ConfigKey.rule.identifier),
    );
  }
}
