// lib/src/models/inheritances_config.dart

import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'details/inheritance_detail.dart';

part 'rules/inheritance_rule.dart';

class InheritancesConfig {
  final List<InheritanceRule> rules;

  const InheritancesConfig({required this.rules});

  InheritanceRule? ruleFor(String componentId) {
    return rules.firstWhereOrNull((rule) => rule.on == componentId);
  }

  factory InheritancesConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = map.asMapList(ConfigKey.root.inheritances);
    return InheritancesConfig(
      rules: ruleList.map(InheritanceRule.tryFromMap).whereType<InheritanceRule>().toList(),
    );
  }
}
