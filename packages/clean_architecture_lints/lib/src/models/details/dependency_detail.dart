// lib/src/models/details/dependency_detail.dart

part of 'package:clean_architecture_lints/src/models/dependencies_config.dart';

/// Represents the `allowed` or `forbidden` block within a location rule.
class DependencyDetail {
  final List<String> components;
  final List<String> packages;

  const DependencyDetail({required this.components, required this.packages});

  bool get isEmpty => components.isEmpty && packages.isEmpty;

  bool get isNotEmpty => components.isNotEmpty || packages.isNotEmpty;

  factory DependencyDetail.fromMap(Map<String, dynamic> map) {
    return DependencyDetail(
      components: map.asStringList(ConfigKey.dependency.component),
      packages: map.asStringList(ConfigKey.dependency.package),
    );
  }
}
