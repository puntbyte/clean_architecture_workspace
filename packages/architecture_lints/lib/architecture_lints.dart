// lib/architecture_lints.dart

import 'package:architecture_lints/src/lints/naming/class_naming_lint.dart';
import 'package:architecture_lints/src/lints/structure/project_structure_lint.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

ArchitectureLintsPlugin createPlugin() => ArchitectureLintsPlugin();

class ArchitectureLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    // We simply return the list of rules. 
    // The rules themselves will handle loading the architecture.yaml in their startUp() method.
    return [
      const ProjectStructureLint(),
      const ClassNamingLint(),
    ];
  }
}
