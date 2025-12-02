// lib/src/models/configs/type_config.dart

import 'package:architecture_lints/src/utils_old/config/config_keys.dart';
import 'package:architecture_lints/src/utils_old/extensions/json_map_extension.dart';

part '../rules/type_rule.dart';

/// Configuration for shared type definitions with support for group-based inheritance.
class TypesConfig {
  /// A flattened map of type rules for O(1) lookup.
  /// Key: `group.key` (e.g., "failure.server", "usecase.unary").
  final Map<String, TypeRule> _registry;

  const TypesConfig(this._registry);

  /// Retrieves a type rule by its dot-notated query key.
  TypeRule? get(String query) => _registry[query];

  factory TypesConfig.fromMap(Map<String, dynamic> map) {
    final root = map.asMap(ConfigKey.root.typeDefinitions);
    final flattened = <String, TypeRule>{};

    // Iterate over each group (e.g., "failure", "usecase", "exception")
    for (final groupEntry in root.entries) {
      final groupName = groupEntry.key;
      final rawRules = groupEntry.value;

      if (rawRules is! List) continue;

      final ruleMaps = rawRules.whereType<Map<String, dynamic>>().toList();

      // 1. Find Base Import (Inheritance Source)
      String? baseImport;
      final baseRuleMap = ruleMaps.firstWhere(
            (r) => r[ConfigKey.type.key] == 'base',
        orElse: () => {},
      );
      if (baseRuleMap.isNotEmpty) {
        baseImport = baseRuleMap[ConfigKey.type.import] as String?;
      }

      // 2. Build Rules with Inheritance
      for (final ruleMap in ruleMaps) {
        final key = ruleMap[ConfigKey.type.key] as String?;

        // Special logic: 'raw' keys usually refer to SDK types (e.g. Exception)
        // and should NOT inherit the package import from 'base'.
        final shouldInherit = key != 'raw';
        final defaultImport = shouldInherit ? baseImport : null;

        final rule = TypeRule.fromMap(ruleMap, defaultImport: defaultImport);

        if (rule.key.isNotEmpty && rule.name.isNotEmpty) {
          flattened['$groupName.${rule.key}'] = rule;
        }
      }
    }

    return TypesConfig(flattened);
  }
}
