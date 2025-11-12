// lib/src/models/rules/naming_rule.dart

import 'package:clean_architecture_kit/src/utils/extensions/json_map_extension.dart';

/// Represents a single naming rule with allowed and forbidden patterns.
class NamingRule {
  final String pattern;
  final String? antipattern;
  final String? grammar;

  const NamingRule({
    required this.pattern,
    this.antipattern,
    this.grammar,
  });

  factory NamingRule.from(dynamic data, String defaultPattern) {
    if (data is String) return NamingRule(pattern: data);

    if (data is Map<String, dynamic>) {
      return NamingRule(
        pattern: data.getString('pattern', defaultPattern),
        antipattern: data.getOptionalString('antipattern'),
        grammar: data.getOptionalString('grammar'),
      );
    }

    return NamingRule(pattern: defaultPattern);
  }
}
