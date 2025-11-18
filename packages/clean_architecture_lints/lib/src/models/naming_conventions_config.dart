// lib/src/models/naming_conventions_config.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/utils/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'package:clean_architecture_lints/src/models/rules/naming_rule.dart';

/// The parent configuration class for all naming convention rules.
/// It holds a direct list representation of the rules defined in the YAML.
class NamingConventionsConfig {
  final List<NamingRule> rules;

  const NamingConventionsConfig({required this.rules});

  /// Creates an instance by parsing the `naming_conventions` list from the root map.
  factory NamingConventionsConfig.fromMap(JsonMap map) {
    final ruleList = map.asMapList(ConfigKey.root.namings);

    return NamingConventionsConfig(
      rules: ruleList.map(NamingRule.tryFromMap).whereType<NamingRule>().toList(),
    );
  }

  /// Finds the first matching rule for a given architectural component.
  ///
  /// It searches the list of rules to find one where the `on` property
  /// contains the component's string identifier.
  NamingRule? getRuleFor(ArchComponent component) => rules.firstWhereOrNull(
    (rule) => rule.on.contains(component.id),
  );
}
