// lib/src/models/rules/location_rule.dart

part of 'package:clean_architecture_lints/src/models/locations_config.dart';

/// Represents a single dependency rule for a component or layer.
class LocationRule {
  final List<String> on;
  final LocationDetail allowed;
  final LocationDetail forbidden;

  const LocationRule({required this.on, required this.allowed, required this.forbidden});

  /// Creates an instance from a map, returning null if essential data is missing.
  static LocationRule? fromMap(Map<String, dynamic> map) {
    final on = map.asStringList(ConfigKey.rule.on);
    if (on.isEmpty) return null;

    return LocationRule(
      on: on,
      allowed: LocationDetail.fromMap(map.asMap(ConfigKey.rule.allowed)),
      forbidden: LocationDetail.fromMap(map.asMap(ConfigKey.rule.forbidden)),
    );
  }
}
