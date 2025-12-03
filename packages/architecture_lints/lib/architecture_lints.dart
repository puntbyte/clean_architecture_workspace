// lib/src/architecture_lints_plugin.dart

import 'package:architecture_lints/src/lints/consistency/rules/orphan_file_rule.dart';
import 'package:architecture_lints/src/lints/naming/rules/naming_antipattern_rule.dart';
import 'package:architecture_lints/src/lints/naming/rules/naming_pattern_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Entry point for custom_lint
PluginBase createPlugin() => _ArchitectureLintsPlugin();

class _ArchitectureLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      const OrphanFileRule(),
      const NamingPatternRule(),
      const NamingAntipatternRule(),
    ];
  }
}
