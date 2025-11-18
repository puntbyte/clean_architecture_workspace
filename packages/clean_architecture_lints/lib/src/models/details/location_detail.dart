// lib/src/models/details/location_detail.dart

part of 'package:clean_architecture_lints/src/models/locations_config.dart';

/// Represents the `allowed` or `forbidden` block within a location rule.
class LocationDetail {
  final List<String> components;
  final List<String> packages;

  const LocationDetail({required this.components, required this.packages});

  bool get isEmpty => components.isEmpty && packages.isEmpty;

  bool get isNotEmpty => components.isNotEmpty || packages.isNotEmpty;

  factory LocationDetail.fromMap(Map<String, dynamic> map) {
    return LocationDetail(
      components: map.asStringList('component'),
      packages: map.asStringList('package'),
    );
  }
}
