// lib/src/models/rules/dependency_rule.dart

part of '../dependencies_config.dart';

class DependencyRule {
  final List<String> on;
  final DependencyDetail allowed;
  final DependencyDetail forbidden;

  const DependencyRule({required this.on, required this.allowed, required this.forbidden});

  static DependencyRule? fromMap(Map<String, dynamic> map) {
    final on = map.asStringList(ConfigKey.dependency.on);
    if (on.isEmpty) return null;

    return DependencyRule(
      on: on,
      allowed: DependencyDetail.fromMap(map[ConfigKey.dependency.allowed]),
      forbidden: DependencyDetail.fromMap(map[ConfigKey.dependency.forbidden]),
    );
  }
}
