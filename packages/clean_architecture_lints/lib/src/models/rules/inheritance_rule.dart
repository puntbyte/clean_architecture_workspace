// lib/src/models/rules/inheritance_rule.dart

part of '../inheritances_config.dart';

class InheritanceRule {
  final String on;
  final List<InheritanceDetail> required;
  final List<InheritanceDetail> allowed;
  final List<InheritanceDetail> forbidden;

  const InheritanceRule({
    required this.on,
    this.required = const [],
    this.allowed = const [],
    this.forbidden = const [],
  });

  static InheritanceRule? tryFromMap(Map<String, dynamic> map) {
    final on = map.asString(ConfigKey.rule.on);
    if (on.isEmpty) return null;

    return InheritanceRule(
      on: on,
      required: _parseDetails(map, ConfigKey.rule.required),
      allowed: _parseDetails(map, ConfigKey.rule.allowed),
      forbidden: _parseDetails(map, ConfigKey.rule.forbidden),
    );
  }

  static List<InheritanceDetail> _parseDetails(Map<String, dynamic> map, String key) {
    final data = map[key];

    if (data is Map<String, dynamic>) {
      return InheritanceDetail.fromMapWithExpansion(data);
    }

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .expand(InheritanceDetail.fromMapWithExpansion)
          .toList();
    }

    return [];
  }
}
