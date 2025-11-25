// lib/src/models/type_safeties_config.dart

import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'details/type_safety_detail.dart';

part 'rules/type_safety_rule.dart';

/// The parent configuration class for all type safety rules.
class TypeSafetiesConfig {
  final List<TypeSafetyRule> rules;

  const TypeSafetiesConfig({required this.rules});

  /// Finds rules applicable to a specific component ID.
  List<TypeSafetyRule> rulesFor(String componentId) {
    return rules.where((rule) => rule.on.contains(componentId)).toList();
  }

  /// Gets all parameter rules for a component and parameter identifier.
  List<TypeSafetyDetail> parameterRulesFor(String componentId, String identifier) {
    return rulesFor(
      componentId,
    ).expand((rule) => rule.parameters).where((detail) => detail.identifier == identifier).toList();
  }

  /// Gets all return type rules for a component.
  List<TypeSafetyDetail> returnRulesFor(String componentId) {
    return rulesFor(componentId).expand((rule) => rule.returns).toList();
  }

  /// Factory that parses the `type_safeties` block from YAML.
  factory TypeSafetiesConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = map.asMapList(ConfigKey.root.typeSafeties);

    return TypeSafetiesConfig(
      rules: ruleList.map(TypeSafetyRule.tryFromMap).whereType<TypeSafetyRule>().toList(),
    );
  }
}
