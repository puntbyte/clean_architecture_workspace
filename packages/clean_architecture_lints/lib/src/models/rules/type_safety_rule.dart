// lib/src/models/rules/type_safety_rule.dart
part of '../configs/type_safeties_config.dart';

/// Represents a complete type safety rule for architectural components.
class TypeSafetyRule {
  final List<String> on;
  final List<TypeSafetyDetail> allowed;
  final List<TypeSafetyDetail> forbidden;

  const TypeSafetyRule({
    required this.on,
    this.allowed = const [],
    this.forbidden = const [],
  });

  static TypeSafetyRule? tryFromMap(Map<String, dynamic> map) {
    final on = map.asStringList(ConfigKey.rule.on);
    if (on.isEmpty) return null;

    return TypeSafetyRule(
      on: on,
      allowed: _parseDetails(map, ConfigKey.rule.allowed),
      forbidden: _parseDetails(map, ConfigKey.rule.forbidden),
    );
  }

  static List<TypeSafetyDetail> _parseDetails(Map<String, dynamic> map, String key) {
    final data = map[key];

    // Support single object syntax
    if (data is Map<String, dynamic>) return [TypeSafetyDetail.fromMap(data)];

    // Support list syntax
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(TypeSafetyDetail.fromMap).toList();
    }

    return [];
  }
}
