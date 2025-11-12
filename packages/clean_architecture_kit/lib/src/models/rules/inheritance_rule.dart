import 'package:clean_architecture_kit/src/utils/extensions/json_map_extension.dart';

/// Represents a single, complete inheritance rule for an architectural component.
class InheritanceRule {
  /// The architectural component to apply the rule to (e.g., 'entity').
  final String on;
  /// A list of base classes that are required. If multiple are provided, the class
  /// must be a subtype of AT LEAST ONE of them (OR condition).
  final List<InheritanceDetail> required;
  /// A list of base classes that are forbidden.
  final List<InheritanceDetail> forbidden;
  /// A list of base classes that are suggested (results in an INFO-level hint).
  final List<InheritanceDetail> suggested;

  const InheritanceRule({
    required this.on,
    this.required = const [],
    this.forbidden = const [],
    this.suggested = const [],
  });

  factory InheritanceRule.fromMap(Map<String, dynamic> map) {
    // Helper to parse a key that can be a single map or a list of maps.
    List<InheritanceDetail> parseDetails(String key) {
      final data = map[key];
      if (data is Map<String, dynamic>) {
        final detail = InheritanceDetail.tryFromMap(data);
        return detail != null ? [detail] : [];
      }
      if (data is List) {
        return data.whereType<Map<String, dynamic>>()
            .map(InheritanceDetail.tryFromMap)
            .whereType<InheritanceDetail>()
            .toList();
      }
      return [];
    }

    return InheritanceRule(
      on: map.getString('on'),
      required: parseDetails('required'),
      forbidden: parseDetails('forbidden'),
      suggested: parseDetails('suggested'),
    );
  }
}

/// Represents the details of a single base class in an inheritance rule.
class InheritanceDetail {
  final String name;
  final String import;

  const InheritanceDetail({required this.name, required this.import});

  /// A failable factory. Returns null if essential keys are missing.
  static InheritanceDetail? tryFromMap(Map<String, dynamic> map) {
    final name = map.getString('name');
    final import = map.getString('import');
    if (name.isEmpty || import.isEmpty) return null;
    return InheritanceDetail(name: name, import: import);
  }
}