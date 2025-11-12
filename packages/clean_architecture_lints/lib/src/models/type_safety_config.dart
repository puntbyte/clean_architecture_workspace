// lib/src/models/type_safety_config.dart

import 'package:clean_architecture_kit/src/models/rules/parameter_rule.dart';
import 'package:clean_architecture_kit/src/models/rules/return_rule.dart';

/// The parent configuration class for all type safety rules.
class TypeSafetyConfig {
  final List<ReturnRule> returns;
  final List<ParameterRule> parameters;

  const TypeSafetyConfig({required this.returns, required this.parameters});

  factory TypeSafetyConfig.fromMap(Map<String, dynamic> map) {
    final returnsList = (map['returns'] as List<dynamic>?) ?? [];
    final paramsList = (map['parameters'] as List<dynamic>?) ?? [];

    return TypeSafetyConfig(
      returns: returnsList
          .whereType<Map<String, dynamic>>()
          .map(ReturnRule.tryFromMap)
          .whereType<ReturnRule>()
          .toList(),

      parameters: paramsList
          .whereType<Map<String, dynamic>>()
          .map(ParameterRule.tryFromMap)
          .whereType<ParameterRule>()
          .toList(),
    );
  }
}
