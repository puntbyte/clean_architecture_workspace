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

    // Case 1: Single Map (possibly with list of names)
    // required: { name: ['A', 'B'], import: '...' }
    if (data is Map<String, dynamic>) {
      return InheritanceDetail.fromMapWithExpansion(data);
    }

    // Case 2: List of Maps
    // required: [ {name: 'A', import: '...'}, ... ]
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .expand((item) => InheritanceDetail.fromMapWithExpansion(item))
          .toList();
    }

    return [];
  }
}