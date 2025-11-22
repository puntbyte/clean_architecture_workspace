// lib/src/models/rules/dependency_rule.dart

part of 'package:clean_architecture_lints/src/models/dependencies_config.dart';

/// Represents a single dependency rule for a component or layer.
class DependencyRule {
  final List<String> on;
  final DependencyDetail allowed;
  final DependencyDetail forbidden;

  const DependencyRule({required this.on, required this.allowed, required this.forbidden});

  /// Creates an instance from a map, returning null if essential data is missing.
  static DependencyRule? fromMap(Map<String, dynamic> map) {
    final on = map.asStringList(ConfigKey.dependency.on);
    if (on.isEmpty) return null;

    return DependencyRule(
      on: on,
      allowed: DependencyDetail.fromMap(map.asMap(ConfigKey.dependency.allowed)),
      forbidden: DependencyDetail.fromMap(map.asMap(ConfigKey.dependency.forbidden)),
    );
  }
}
