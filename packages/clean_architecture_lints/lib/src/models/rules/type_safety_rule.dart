// lib/src/models/rules/type_safety_rule.dart

part of 'package:clean_architecture_lints/src/models/type_safeties_config.dart';

/// Represents a complete type safety rule for architectural components.
class TypeSafetyRule {
  final List<String> on;
  final List<TypeSafetyDetail> returns;
  final List<TypeSafetyDetail> parameters;

  const TypeSafetyRule({
    required this.on,
    this.returns = const [],
    this.parameters = const [],
  });

  /// Validates that the rule has at least one return or parameter check.
  bool get isValid => returns.isNotEmpty || parameters.isNotEmpty;

  /// Creates an instance from a map, returning null if essential data is missing.
  static TypeSafetyRule? tryFromMap(Map<String, dynamic> map) {
    final on = map.asStringList(ConfigKey.rule.on);
    if (on.isEmpty) return null;

    final returns = _parseReturns(map);
    final parameters = _parseParameters(map);

    if (returns.isEmpty && parameters.isEmpty) return null;

    return TypeSafetyRule(
      on: on,
      returns: returns,
      parameters: parameters,
    );
  }

  /// Parses return type checks from the map.
  static List<TypeSafetyDetail> _parseReturns(Map<String, dynamic> map) {
    final returnsData = map['returns'];
    if (returnsData is Map<String, dynamic>) {
      final detail = TypeSafetyDetail.tryFromMap(returnsData);
      return detail != null ? [detail] : [];
    }
    return [];
  }

  /// Parses parameter type checks from the map.
  static List<TypeSafetyDetail> _parseParameters(Map<String, dynamic> map) {
    final paramsData = map['parameters'];
    if (paramsData is List) {
      return paramsData
          .whereType<Map<String, dynamic>>()
          .map(TypeSafetyDetail.tryFromMap)
          .whereType<TypeSafetyDetail>()
          .toList();
    }
    return [];
  }
}
