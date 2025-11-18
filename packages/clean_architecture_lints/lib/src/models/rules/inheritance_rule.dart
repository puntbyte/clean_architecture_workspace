// lib/src/models/rules/inheritance_rule.dart

part of 'package:clean_architecture_lints/src/models/inheritances_config.dart';

/// Represents a single, user-defined inheritance rule.
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

  /// Creates an instance from a map, returning null if essential data is missing.
  static InheritanceRule? tryFromMap(Map<String, dynamic> map) {
    final on = _parseOn(map);
    if (on == null) return null;

    return InheritanceRule(
      on: on,
      required: _parseDetails(map, ConfigKey.rule.required),
      allowed: _parseDetails(map, ConfigKey.rule.allowed),
      forbidden: _parseDetails(map, ConfigKey.rule.forbidden),
    );
  }

  /// Parses the 'on' field, returning null if empty or missing.
  static String? _parseOn(Map<String, dynamic> map) {
    final on = map.asString(ConfigKey.rule.on);
    return on.isEmpty ? null : on;
  }

  /// Parses details for a given key (required/allowed/forbidden).
  static List<InheritanceDetail> _parseDetails(Map<String, dynamic> map, String key) {
    final data = map[key];

    if (data is Map<String, dynamic>) {
      final detail = InheritanceDetail.tryFromMap(data);
      return detail != null ? [detail] : [];
    }

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(InheritanceDetail.tryFromMap)
          .whereType<InheritanceDetail>()
          .toList();
    }

    return [];
  }
}
