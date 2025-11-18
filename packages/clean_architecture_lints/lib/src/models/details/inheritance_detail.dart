// lib/src/models/details/inheritance_detail.dart

part of 'package:clean_architecture_lints/src/models/inheritances_config.dart';

/// Represents the details of a single base class in an inheritance rule.
class InheritanceDetail {
  final String name;
  final String import;

  const InheritanceDetail({
    required this.name,
    required this.import,
  });

  /// Creates an instance from a map, returning null if required fields are missing.
  static InheritanceDetail? tryFromMap(Map<String, dynamic> map) {
    final name = map.asString(ConfigKey.rule.name);
    final import = map.asString(ConfigKey.rule.import);

    if (name.isEmpty || import.isEmpty) return null;

    return InheritanceDetail(name: name, import: import);
  }
}
