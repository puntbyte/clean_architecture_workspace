// lib/src/lints/naming/enforce_naming_antipattern.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_strategy.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes do not use forbidden naming patterns (e.g., `{{name}}Entity`).
class EnforceNamingAntipattern extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_naming_antipattern',
    problemMessage: 'The {1} name "{0}" matches the forbidden pattern "{2}".',
    correctionMessage: 'Rename the class to avoid this pattern. (e.g., remove the suffix if forbidden).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final NamingStrategy _namingStrategy;

  EnforceNamingAntipattern({
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

      final rule = config.namingConventions.ruleFor(actualComponent);
      if (rule == null || rule.antipattern == null || rule.antipattern!.isEmpty) return;

      // 1. Determine Structural Identity (Inheritance)
      final element = node.declaredFragment?.element;
      final structuralComponent = element != null
          ? layerResolver.getComponentFromSupertype(element)
          : null;

      // 2. Pre-Check: Is this actually a Location Error?
      // If the class name strongly suggests another component AND inheritance doesn't prove otherwise,
      // we yield to EnforceFileAndFolderLocation.
      if (_namingStrategy.shouldYieldToLocationLint(
          className, actualComponent, structuralComponent)) {
        return;
      }

      // 3. Antipattern Check
      if (NamingUtils.validateName(name: className, template: rule.antipattern!)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [
            className,             // {0} UserEntity
            actualComponent.label, // {1} Entity
            rule.antipattern!,     // {2} {{name}}Entity
          ],
        );
      }
    });
  }
}
