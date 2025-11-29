// lib/src/models/type_safeties_config.dart

import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part '../details/type_safety_detail.dart';
part '../rules/type_safety_rule.dart';

class TypeSafetiesConfig {
  final List<TypeSafetyRule> rules;

  const TypeSafetiesConfig({required this.rules});

  List<TypeSafetyRule> rulesFor(String componentId) {
    return rules.where((rule) => rule.on.contains(componentId)).toList();
  }

  factory TypeSafetiesConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = map.asMapList(ConfigKey.root.typeSafeties);
    return TypeSafetiesConfig(
      rules: ruleList.map(TypeSafetyRule.tryFromMap).whereType<TypeSafetyRule>().toList(),
    );
  }
}
