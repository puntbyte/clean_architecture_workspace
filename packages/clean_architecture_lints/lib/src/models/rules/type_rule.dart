// lib/src/models/rules/type_rule.dart

part of '../type_config.dart';

/// Represents a single type definition (name and optional import).
class TypeRule {
  final String name;
  final String? import;

  const TypeRule({required this.name, this.import});

  factory TypeRule.fromMap(Map<String, dynamic> map) {
    return TypeRule(
      name: map.asString(ConfigKey.type.name),
      import: map.asStringOrNull(ConfigKey.type.import),
    );
  }
}
