// lib/src/models/rules/annotation_rule.dart

part of 'package:clean_architecture_lints/src/models/annotations_config.dart';

/// Represents a complete annotation rule for architectural components.
class AnnotationRule {
  final List<String> on;
  final List<AnnotationDetail> required;
  final List<AnnotationDetail> allowed;
  final List<AnnotationDetail> forbidden;

  const AnnotationRule({
    required this.on,
    this.required = const [],
    this.allowed = const [],
    this.forbidden = const [],
  });

  /// Creates an instance from a map, returning null if essential data is missing.
  static AnnotationRule? tryFromMap(Map<String, dynamic> map) {
    final on = _parseOn(map);
    if (on == null) return null;

    return AnnotationRule(
      on: on,
      required: _parseDetails(map, ConfigKey.rule.required),
      forbidden: _parseDetails(map, ConfigKey.rule.forbidden),
      allowed: _parseDetails(map, ConfigKey.rule.allowed),
    );
  }

  /// Parses the 'on' field, returning null if empty or missing.
  static List<String>? _parseOn(Map<String, dynamic> map) {
    final on = map.asStringList(ConfigKey.rule.on);
    return on.isEmpty ? null : on;
  }

  /// Parses details for a given key (required/forbidden/allowed).
  static List<AnnotationDetail> _parseDetails(Map<String, dynamic> map, String key) {
    final data = map[key];

    if (data is Map<String, dynamic>) return _parseSingleDetailMap(data);

    if (data is List) return _parseDetailList(data);

    return [];
  }

  /// Parses a single detail map, handling list name expansion.
  static List<AnnotationDetail> _parseSingleDetailMap(Map<String, dynamic> data) {
    final nameValue = data['name'];
    if (nameValue is List) return _expandNameList(nameValue, data['import'] as String?);

    final detail = AnnotationDetail.tryFromMap(data);
    return detail != null ? [detail] : [];
  }

  /// Creates multiple AnnotationDetail instances from a list of names.
  static List<AnnotationDetail> _expandNameList(List<dynamic> nameValue, String? import) {
    return nameValue
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .map((name) => AnnotationDetail(name: name, import: import))
        .toList();
  }

  /// Parses a list of detail maps, expanding any with list names.
  static List<AnnotationDetail> _parseDetailList(List<dynamic> data) {
    return data
        .whereType<Map<String, dynamic>>()
        .expand(_expandIfNameIsList)
        .map(AnnotationDetail.tryFromMap)
        .whereType<AnnotationDetail>()
        .toList();
  }

  /// Expands a detail map with a list of names into multiple maps.
  static List<Map<String, dynamic>> _expandIfNameIsList(Map<String, dynamic> item) {
    final nameValue = item['name'];
    if (nameValue is List) {
      return [
        for (final name in nameValue) {'name': name, 'import': item['import']},
      ];
    }
    return [item];
  }
}
