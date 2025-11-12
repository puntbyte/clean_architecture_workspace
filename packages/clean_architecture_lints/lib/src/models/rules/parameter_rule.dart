// lib/src/models/rules/parameter_rule.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// A rule for enforcing a specific parameter type.
class ParameterRule {
  final String type;
  final List<String> where;
  final String? importPath;
  final String? identifier;

  const ParameterRule({
    required this.type,
    required this.where,
    this.importPath,
    this.identifier,
  });

  /// A failable factory. Returns null if essential keys are missing.
  static ParameterRule? tryFromMap(Map<String, dynamic> map) {
    final type = map.getString('type');
    final where = map.getList('where');

    if (type.isEmpty || where.isEmpty) return null;

    return ParameterRule(
      type: type,
      where: where,
      importPath: map.getOptionalString('import'),
      identifier: map.getOptionalString('identifier'),
    );
  }
}
