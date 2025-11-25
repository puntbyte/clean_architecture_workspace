// lib/src/models/details/type_safety_detail.dart

part of '../type_safeties_config.dart';

/// Represents a single type safety check for either a return type or parameter.
class TypeSafetyDetail {
  final String unsafeType;
  final String safeType;
  final String? import;
  final String? identifier; // null for return type checks

  const TypeSafetyDetail({
    required this.unsafeType,
    required this.safeType,
    this.import,
    this.identifier,
  });

  /// Determines if this is a parameter check (has identifier) or return check.
  bool get isParameterCheck => identifier != null && identifier!.isNotEmpty;

  /// Creates an instance from a map, returning null if required fields are missing.
  static TypeSafetyDetail? tryFromMap(Map<String, dynamic> map) {
    final unsafeType = map.asString(ConfigKey.rule.unsafeType);
    final safeType = map.asString(ConfigKey.rule.safeType);

    if (unsafeType.isEmpty || safeType.isEmpty) return null;

    return TypeSafetyDetail(
      unsafeType: unsafeType,
      safeType: safeType,
      import: map.asStringOrNull(ConfigKey.rule.import),
      identifier: map.asStringOrNull(ConfigKey.rule.identifier),
    );
  }
}
