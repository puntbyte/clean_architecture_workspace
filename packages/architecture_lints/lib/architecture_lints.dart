// lib/src/architecture_lints_plugin.dart

import 'package:architecture_lints/src/lints/boundaries/rules/component_dependency_rule.dart';
import 'package:architecture_lints/src/lints/boundaries/rules/external_dependency_rule.dart';
import 'package:architecture_lints/src/lints/boundaries/rules/module_dependency_rule.dart';
import 'package:architecture_lints/src/lints/consistency/rules/orphan_file_rule.dart';
import 'package:architecture_lints/src/lints/consistency/rules/parity_missing_rule.dart';
import 'package:architecture_lints/src/lints/debug_component_identity.dart';
import 'package:architecture_lints/src/lints/identity/rules/inheritance_allowed_rule.dart';
import 'package:architecture_lints/src/lints/identity/rules/inheritance_forbidden_rule.dart';
import 'package:architecture_lints/src/lints/identity/rules/inheritance_required_rule.dart';
import 'package:architecture_lints/src/lints/members/rules/member_forbidden_rule.dart';
import 'package:architecture_lints/src/lints/members/rules/member_required_rule.dart';
import 'package:architecture_lints/src/lints/metadata/rules/annotation_forbidden_rule.dart';
import 'package:architecture_lints/src/lints/metadata/rules/annotation_required_rule.dart';
import 'package:architecture_lints/src/lints/metadata/rules/annotation_strict_rule.dart';
import 'package:architecture_lints/src/lints/naming/rules/grammar_rule.dart';
import 'package:architecture_lints/src/lints/naming/rules/misplaced_component_rule.dart';
import 'package:architecture_lints/src/lints/naming/rules/naming_antipattern_rule.dart';
import 'package:architecture_lints/src/lints/naming/rules/naming_pattern_rule.dart';
import 'package:architecture_lints/src/lints/safety/rules/exception_conversion_rule.dart';
import 'package:architecture_lints/src/lints/safety/rules/exception_forbidden_rule.dart';
import 'package:architecture_lints/src/lints/safety/rules/exception_required_rule.dart';
import 'package:architecture_lints/src/lints/safety/rules/type_safety_param_allowed_rule.dart';
import 'package:architecture_lints/src/lints/safety/rules/type_safety_param_forbidden_rule.dart';
import 'package:architecture_lints/src/lints/safety/rules/type_safety_return_allowed_rule.dart';
import 'package:architecture_lints/src/lints/safety/rules/type_safety_return_forbidden_rule.dart';
import 'package:architecture_lints/src/lints/usages/rules/global_access_forbidden_rule.dart';
import 'package:architecture_lints/src/lints/usages/rules/instantiation_forbidden_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Entry point for custom_lint
PluginBase createPlugin() => _ArchitectureLintsPlugin();

class _ArchitectureLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    return [
      const DebugComponentIdentity(),

      const OrphanFileRule(),

      const NamingPatternRule(),
      const NamingAntipatternRule(),
      const GrammarRule(),
      const MisplacedComponentRule(),

      const ComponentDependencyRule(),
      const ExternalDependencyRule(),
      const ModuleDependencyRule(),

      const InheritanceRequiredRule(),
      const InheritanceAllowedRule(),
      const InheritanceForbiddenRule(),

      const TypeSafetyReturnAllowedRule(),
      const TypeSafetyReturnForbiddenRule(),
      const TypeSafetyParamAllowedRule(),
      const TypeSafetyParamForbiddenRule(),

      const ExceptionForbiddenRule(),
      const ExceptionRequiredRule(),
      const ExceptionConversionRule(),

      const MemberRequiredRule(),
      const MemberForbiddenRule(),

      const GlobalAccessForbiddenRule(),
      const InstantiationForbiddenRule(),

      const AnnotationRequiredRule(),
      const AnnotationForbiddenRule(),
      const AnnotationStrictRule(),

      const ParityMissingRule(),
    ];
  }
}
