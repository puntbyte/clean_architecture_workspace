// lib/src/models/details/dependency_detail.dart

part of '../dependencies_config.dart';

class DependencyDetail {
  final List<String> components;
  final List<String> packages;

  const DependencyDetail({
    required this.components,
    required this.packages,
  });

  bool get isEmpty => components.isEmpty && packages.isEmpty;

  bool get isNotEmpty => components.isNotEmpty || packages.isNotEmpty;

  factory DependencyDetail.fromMap(dynamic data) {
    // 1. Handle Shorthand: allowed: ['domain', 'manager']
    // If the value is a List, assume they are Components.
    if (data is List) {
      return DependencyDetail(
        components: data.map((e) => e.toString()).toList(),
        packages: [],
      );
    }

    // 2. Handle Explicit Map: allowed: { component: [...], package: [...] }
    if (data is Map) {
      final map = JsonMap.from(data);
      return DependencyDetail(
        components: map.asStringList(ConfigKey.dependency.component),
        packages: map.asStringList(ConfigKey.dependency.package),
      );
    }

    // 3. Default empty
    return const DependencyDetail(components: [], packages: []);
  }
}
