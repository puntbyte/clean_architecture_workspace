// lib/src/lints/naming/enforce_naming_pattern.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_strategy.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes follow the required syntactic naming pattern.
class EnforceNamingPattern extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_naming_pattern',
    problemMessage: 'The {2} name "{0}" does not match the required pattern "{1}".',
    correctionMessage: 'Rename the class to follow the structure "{1}".',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final NamingStrategy _namingStrategy;

  EnforceNamingPattern({
    required super.config,
    required super.layerResolver,
  }) : _namingStrategy = NamingStrategy(config.namingConventions.rules),
       super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      final actualComponent = layerResolver.getComponent(filePath, className: className);
      if (actualComponent == ArchComponent.unknown) return;

      final rule = config.namingConventions.getRuleFor(actualComponent);
      if (rule == null) return;

      if (_namingStrategy.shouldYieldToLocationLint(className, actualComponent)) {
        return;
      }

      if (!NamingUtils.validateName(name: className, template: rule.pattern)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [
            className, // {0} User
            rule.pattern, // {1} {{name}}Model
            actualComponent.label, // {2} Model
          ],
        );
      }
    });
  }
}
