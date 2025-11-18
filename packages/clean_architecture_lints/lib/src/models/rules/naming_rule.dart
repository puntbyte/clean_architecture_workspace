// lib/src/models/rules/naming_rule.dart

import 'package:clean_architecture_lints/src/utils/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

class NamingRule {
  final List<String> on;
  final String pattern;
  final String? antipattern;
  final String? grammar;

  const NamingRule({required this.on, required this.pattern, this.antipattern, this.grammar});

  static NamingRule? tryFromMap(JsonMap map) {
    final on = map.asStringList(ConfigKey.rule.on);
    if (on.isEmpty) return null;

    // THE IMPROVEMENT: If `pattern` is missing but `grammar` exists, default pattern to `{{name}}`.
    var pattern = map.asString(ConfigKey.rule.pattern);
    final grammar = map.asStringOrNull(ConfigKey.rule.grammar);

    if (pattern.isEmpty && grammar != null && grammar.isNotEmpty) {
      pattern = '{{name}}';
    }

    // A rule must have a final, valid pattern.
    if (pattern.isEmpty) return null;

    return NamingRule(
      on: on,
      pattern: pattern,
      antipattern: map.asStringOrNull(ConfigKey.rule.antipattern),
      grammar: grammar,
    );
  }
}