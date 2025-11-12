// lib/src/lints/enforce_naming_conventions.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:clean_architecture_kit/src/models/rules/naming_rule.dart';
import 'package:clean_architecture_kit/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes in architectural layers follow the configured naming conventions.
///
/// This lint is intelligent and cooperative, using a prioritized, multi-step logic:
/// 1.  It first checks if a class is clearly in the wrong location (e.g., a `UserModel`
///     in an `entities` directory). If so, it stays silent to let the more specific
///     `enforce_file_and_folder_location` lint report the error, avoiding noise.
/// 2.  It then checks for forbidden `anti_pattern`s for the class's location.
/// 3.  Finally, it checks if the class name matches the required `pattern`.
class EnforceNamingConventions extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_naming_conventions',
    problemMessage: 'The name `{0}` does not follow the required naming conventions for a {1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceNamingConventions({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // Pre-build the list of all possible rules for efficiency.
    final allComponentRules = _getComponentRules(config.naming);

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      // 1. Determine the correct rule and user-friendly type name for this class.
      final (rule: ruleForClass, classType: classType) = _getRuleForClass(
        filePath: filePath,
        className: className,
        allRules: allComponentRules,
      );

      if (ruleForClass == null || classType == null) return;

      // 2. Check for mislocation first to avoid redundant warnings.
      if (_isMislocated(className: className, allRules: allComponentRules, filePath: filePath)) {
        return;
      }

      // 3. Perform the actual pattern and anti-pattern validation.
      _validateClassName(
        className: className,
        classType: classType,
        rule: ruleForClass,
        node: node,
        reporter: reporter,
      );
    });
  }

  /// Determines the single, most appropriate naming rule for a given class.
  ({NamingRule? rule, String? classType}) _getRuleForClass({
    required String filePath,
    required String className,
    required List<_ComponentRule> allRules,
  }) {
    final actualSubLayer = layerResolver.getSubLayer(filePath);
    if (actualSubLayer == ArchSubLayer.unknown) return (rule: null, classType: null);

    // First, check if the class is a specific component (e.g., Event, State).
    final actualComponent = layerResolver.getSubLayerComponent(filePath, className);
    if (actualComponent != SubLayerComponent.unknown) {
      final componentRule = allRules.firstWhereOrNull((r) => r.component == actualComponent);
      return (rule: componentRule?.rule, classType: actualComponent.label);
    }

    // If not a component, it's a general sub-layer class.
    final subLayerRule = allRules.firstWhereOrNull((r) => r.subLayer == actualSubLayer);
    return (rule: subLayerRule?.rule, classType: actualSubLayer.label);
  }

  /// Checks if a class appears to be in the wrong location.
  bool _isMislocated({
    required String className,
    required List<_ComponentRule> allRules,
    required String filePath,
  }) {
    final actualSubLayer = layerResolver.getSubLayer(filePath);

    // Sort rules to check more specific patterns first.
    final sortedRules = List<_ComponentRule>.from(allRules)
      ..sort((a, b) => b.rule.pattern.length.compareTo(a.rule.pattern.length));

    final bestGuessRule = sortedRules.firstWhereOrNull(
          (rule) => NamingUtils.validateName(name: className, template: rule.rule.pattern),
    );

    // It's mislocated if its name suggests a different sub-layer.
    return bestGuessRule != null && bestGuessRule.subLayer != actualSubLayer;
  }

  /// Performs the final pattern and anti-pattern checks and reports errors.
  void _validateClassName({
    required String className,
    required String classType,
    required NamingRule rule,
    required ClassDeclaration node,
    required DiagnosticReporter reporter,
  }) {
    // GATE 1: ANTI-PATTERN CHECK
    if (rule.antipattern != null) {
      if (NamingUtils.validateName(name: className, template: rule.antipattern!)) {
        reporter.atToken(
          node.name,
          LintCode(
            name: _code.name,
            problemMessage: 'The name `$className` uses a forbidden pattern for a $classType.',
          ),
        );
        return; // Definitive violation found, stop.
      }
    }

    // GATE 2: PATTERN CHECK
    if (!NamingUtils.validateName(name: className, template: rule.pattern)) {
      reporter.atToken(
        node.name,
        LintCode(
          name: _code.name,
          problemMessage: 'The name `$className` does not match the required `${rule.pattern}` convention for a $classType.',
        ),
      );
    }
  }

  /// A helper to create a list of all component rules from the naming configuration.
  List<_ComponentRule> _getComponentRules(NamingConfig naming) {
    return [
      // Sub-Layer Rules
      _ComponentRule(rule: naming.entity, subLayer: ArchSubLayer.entity),
      _ComponentRule(rule: naming.model, subLayer: ArchSubLayer.model),
      _ComponentRule(rule: naming.useCase, subLayer: ArchSubLayer.useCase),
      _ComponentRule(rule: naming.repository, subLayer: ArchSubLayer.domainRepository),
      _ComponentRule(rule: naming.repositoryImplementation, subLayer: ArchSubLayer.dataRepository),
      _ComponentRule(rule: naming.dataSource, subLayer: ArchSubLayer.dataSource),
      _ComponentRule(rule: naming.dataSourceImplementation, subLayer: ArchSubLayer.dataSource),
      _ComponentRule(rule: naming.manager, subLayer: ArchSubLayer.manager),

      // Component-Specific Rules
      _ComponentRule(rule: naming.event, component: SubLayerComponent.event),
      _ComponentRule(rule: naming.eventImplementation, component: SubLayerComponent.eventImplementation),
      _ComponentRule(rule: naming.state, component: SubLayerComponent.state),
      _ComponentRule(rule: naming.stateImplementation, component: SubLayerComponent.stateImplementation),
    ];
  }
}

/// A private helper class to associate a naming rule with its architectural role.
class _ComponentRule {
  final NamingRule rule;
  final ArchSubLayer? subLayer;
  final SubLayerComponent? component;


  const _ComponentRule({
    required this.rule,
    this.subLayer,
    this.component,
  });
}
