// lib/src/models/rules/return_rule.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// A rule for enforcing a specific return type.
class ReturnRule {
  final String type;
  final List<String> where;
  final String? importPath;

  const ReturnRule({
    required this.type,
    required this.where,
    this.importPath,
  });

  /// A failable factory. Returns null if essential keys are missing.
  static ReturnRule? tryFromMap(Map<String, dynamic> map) {
    final type = map.getString('type');
    final where = map.getList('where');

    if (type.isEmpty || where.isEmpty) return null;

    return ReturnRule(
      type: type,
      where: where,
      importPath: map.getOptionalString('import'),
    );
  }
}
