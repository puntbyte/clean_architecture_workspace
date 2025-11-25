// lib/src/models/rules/annotation_rule.dart
part of '../configs/annotations_config.dart';

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

  static AnnotationRule? tryFromMap(Map<String, dynamic> map) {
    final on = map.asStringList(ConfigKey.rule.on);
    if (on.isEmpty) return null;

    return AnnotationRule(
      on: on,
      required: _parseDetails(map[ConfigKey.rule.required]),
      forbidden: _parseDetails(map[ConfigKey.rule.forbidden]),
      allowed: _parseDetails(map[ConfigKey.rule.allowed]),
    );
  }

  /// Parses the 'required', 'allowed', or 'forbidden' block.
  /// Can be a List of Maps OR a single Map with a list of names.
  static List<AnnotationDetail> _parseDetails(dynamic data) {
    if (data == null) return [];

    // Case 1: List of Maps (Old format or explicit details)
    // forbidden: [ {name: 'A'}, {name: 'B'} ]
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .expand(_parseSingleMapEntry) // Handle expansion within list items too
          .toList();
    }

    // Case 2: Single Map (New format with shared import)
    // forbidden: { name: ['A', 'B'], import: 'pkg' }
    if (data is Map) {
      return _parseSingleMapEntry(data.cast<String, dynamic>());
    }

    return [];
  }

  /// Parses a single map entry, expanding if 'name' is a list.
  static List<AnnotationDetail> _parseSingleMapEntry(Map<String, dynamic> map) {
    final nameValue = map[ConfigKey.rule.name];
    final importValue = map[ConfigKey.rule.import] as String?;

    // Expansion: name: ['A', 'B'] -> [Detail(A, import), Detail(B, import)]
    if (nameValue is List) {
      return nameValue.map((n) {
        var name = n.toString();
        if (name.startsWith('@')) name = name.substring(1);
        return AnnotationDetail(name: name, import: importValue);
      }).toList();
    }

    // Single: name: 'A'
    if (nameValue is String) {
      var name = nameValue;
      if (name.startsWith('@')) name = name.substring(1);
      return [AnnotationDetail(name: name, import: importValue)];
    }

    return [];
  }
}
