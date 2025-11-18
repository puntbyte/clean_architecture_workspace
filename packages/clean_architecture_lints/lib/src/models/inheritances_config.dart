// lib/src/models/inheritances_config.dart

import 'package:clean_architecture_lints/src/utils/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'details/inheritance_detail.dart';
part 'rules/inheritance_rule.dart';

/// The parent configuration class for all custom, user-defined inheritance rules.
class InheritancesConfig {
  final List<InheritanceRule> rules;

  const InheritancesConfig({required this.rules});

  /// Finds the specific rule for a given architectural component ID.
  InheritanceRule? ruleFor(String componentId) {
    return rules.firstWhereOrNull((rule) => rule.on == componentId);
  }

  /// Factory that parses the `inheritances` block from YAML.
  factory InheritancesConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = map.asMapList(ConfigKey.root.inheritances);

    return InheritancesConfig(
      rules: ruleList
          .map(InheritanceRule.tryFromMap)
          .whereType<InheritanceRule>()
          .toList(),
    );
  }
}
