// lib/src/config/schema/component_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

@immutable
class ComponentConfig {
  /// The unique identifier from the YAML key (e.g., 'domain.usecase').
  final String id;

  /// Human-readable label (e.g., 'Repository Interface').
  final String? name;

  /// The file system paths.
  final List<String> paths;

  /// The required naming patterns.
  final List<String> patterns;

  /// The forbidden naming patterns.
  final List<String> antipatterns;

  final List<String> grammar; // New Field

  /// Whether this is a default component definition.
  final bool isDefault;

  const ComponentConfig({
    required this.id,
    this.name,
    this.paths = const [],
    this.patterns = const [],
    this.antipatterns = const [],
    this.grammar = const [], // New
    this.isDefault = false,
  });

  factory ComponentConfig.fromMap(String key, Map<dynamic, dynamic> map) {
    return ComponentConfig(
      id: key,
      name: map.tryGetString(ConfigKeys.component.name),
      paths: map.getStringList(ConfigKeys.component.path),
      patterns: map.getStringList(ConfigKeys.component.pattern),
      antipatterns: map.getStringList(ConfigKeys.component.antipattern),
      grammar: map.getStringList(ConfigKeys.component.grammar),
      isDefault: map.getBool(ConfigKeys.component.default$),
    );
  }

  factory ComponentConfig.fromMapEntry(MapEntry<String, Map<String, dynamic>> entry) {
    return ComponentConfig.fromMap(entry.key, entry.value);
  }

  String get displayName {
    if (name != null) return name!;

    return id
        .split('.')
        .where((s) => s.isNotEmpty)
        .map((s) => '${s[0].toUpperCase()}${s.substring(1)}')
        .join(' ');
  }

  @override
  String toString() {
    return 'ComponentConfig(id: $id, name: $name, paths: $paths)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ComponentConfig &&
        other.id == id &&
        other.name == name &&
        other.isDefault == isDefault &&
        const ListEquality<String>().equals(other.paths, paths) &&
        const ListEquality<String>().equals(other.patterns, patterns) &&
        const ListEquality<String>().equals(other.antipatterns, antipatterns) &&
        const ListEquality<String>().equals(other.grammar, grammar);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        isDefault.hashCode ^
        const ListEquality<String>().hash(paths) ^
        const ListEquality<String>().hash(patterns) ^
        const ListEquality<String>().hash(antipatterns) ^
        const ListEquality<String>().hash(grammar);
  }
}
