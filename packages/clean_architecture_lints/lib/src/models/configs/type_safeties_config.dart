// lib/src/models/type_safeties_config.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part '../details/type_safety_detail.dart';

part '../rules/type_safety_rule.dart';

/// The parent configuration class for all type safety rules.
class TypeSafetiesConfig {
  final List<TypeSafetyRule> rules;

  const TypeSafetiesConfig({required this.rules});

  /// Factory that parses the `type_safeties` block from YAML.
  factory TypeSafetiesConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = map.asMapList(ConfigKey.root.typeSafeties);
    return TypeSafetiesConfig(
      rules: ruleList.map(TypeSafetyRule.tryFromMap).whereType<TypeSafetyRule>().toList(),
    );
  }

  /// Finds rules applicable to a specific component.
  List<TypeSafetyRule> rulesFor(ArchComponent component) {
    return rules.where((rule) => rule.on.contains(component.id)).toList();
  }
}
