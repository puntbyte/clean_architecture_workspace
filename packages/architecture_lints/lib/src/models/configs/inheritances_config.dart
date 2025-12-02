// lib/src/models/configs/inheritances_config.dart

import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/models/configs/type_config.dart';
import 'package:architecture_lints/src/utils_old/config/config_keys.dart';
import 'package:architecture_lints/src/utils_old/extensions/iterable_extension.dart';
import 'package:architecture_lints/src/utils_old/extensions/json_map_extension.dart';

part '../details/inheritance_detail.dart';

part '../rules/inheritance_rule.dart';

class InheritancesConfig {
  final List<InheritanceRule> rules;

  const InheritancesConfig({required this.rules});

  // Accept TypesConfig here
  factory InheritancesConfig.fromMap(Map<String, dynamic> map, TypesConfig typeDefinitions) {
    final ruleList = map.asMapList(ConfigKey.root.inheritances);

    return InheritancesConfig(
      rules: ruleList
          .map((m) => InheritanceRule.tryFromMap(m, typeDefinitions)) // Pass it down
          .whereType<InheritanceRule>()
          .toList(),
    );
  }

  /// Finds the specific rule for a given architectural component.
  InheritanceRule? ruleFor(ArchComponent component) {
    return rules.firstWhereOrNull((rule) => rule.on == component.id);
  }
}
