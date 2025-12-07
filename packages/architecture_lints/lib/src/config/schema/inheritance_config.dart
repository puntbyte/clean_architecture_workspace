// lib/src/config/schema/inheritance_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class InheritanceConfig {
  final List<String> onIds;
  final List<Definition> required;
  final List<Definition> allowed;
  final List<Definition> forbidden;

  const InheritanceConfig({
    required this.onIds,
    required this.required,
    required this.allowed,
    required this.forbidden,
  });

  factory InheritanceConfig.fromMap(Map<dynamic, dynamic> map) {
    return InheritanceConfig(
      onIds: map.getStringList(ConfigKeys.inheritance.on),
      required: _parseDefinitionList(map[ConfigKeys.inheritance.required]),
      allowed: _parseDefinitionList(map[ConfigKeys.inheritance.allowed]),
      forbidden: _parseDefinitionList(map[ConfigKeys.inheritance.forbidden]),
    );
  }

  /// Parses a list of Maps into a list of InheritanceConfigs.
  static List<InheritanceConfig> parseList(List<Map<String, dynamic>> list) {
    return list.map(InheritanceConfig.fromMap).toList();
  }

  static List<Definition> _parseDefinitionList(dynamic value) {
    if (value == null) return const [];

    // Case 1: Standard List (e.g. required: [ 'Entity', { type: 'Base' } ])
    if (value is List) {
      return value.map(Definition.fromDynamic).toList();
    }

    // Case 2: Map Shorthand (e.g. required: { definition: ['usecase.unary', 'usecase.nullary'] })
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      // Expansion Logic:
      // Since Definition.ref is singular, we must expand a list of refs
      // into multiple Definition objects.
      final defs = map[ConfigKeys.definition.definition];
      if (defs is List) {
        return defs.map((ref) => Definition(ref: ref.toString())).toList();
      }

      // Note: We do NOT need to expand 'type': ['A', 'B'] here,
      // because Definition.fromDynamic handles 'type' as a list internally now.

      // Fallback: Parse as a single definition object
      return [Definition.fromDynamic(value)];
    }

    // Case 3: Single String shorthand (e.g. required: 'Entity')
    return [Definition.fromDynamic(value)];
  }
}
