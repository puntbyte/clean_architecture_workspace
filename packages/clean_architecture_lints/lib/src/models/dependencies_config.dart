// lib/src/models/dependencies_config.dart

import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'package:clean_architecture_lints/src/models/rules/dependency_rule.dart';

part 'package:clean_architecture_lints/src/models/details/dependency_detail.dart';

/// The parent configuration class for all dependency location rules.
class DependenciesConfig {
  final List<DependencyRule> rules;
  final Map<String, DependencyRule> _ruleMap;

  DependenciesConfig({required this.rules})
    : _ruleMap = {
        for (final rule in rules)
          for (final id in rule.on) id: rule,
      };

  /// Finds the specific rule for a given architectural component ID.
  DependencyRule? ruleFor(String componentId) => _ruleMap[componentId];

  /// Factory that parses the `locations` block from YAML.
  factory DependenciesConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = map.asMapList(ConfigKey.root.dependencies);

    return DependenciesConfig(
      rules: ruleList.map(DependencyRule.fromMap).whereType<DependencyRule>().toList(),
    );
  }
}
