import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/naming_strategy_helper.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes do not use forbidden naming patterns (e.g., `{{name}}Entity`).
class EnforceNamingAntipattern extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_naming_antipattern',
    problemMessage: 'The name `{0}` uses a forbidden pattern for a {1}.',
    correctionMessage: 'Rename the class to avoid the forbidden pattern.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final NamingStrategyHelper _namingHelper;

  EnforceNamingAntipattern({required super.config, required super.layerResolver})
      : _namingHelper = NamingStrategyHelper(config.namingConventions.rules),
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

      // If no antipattern is defined for this component, skip.
      if (rule.antipattern == null || rule.antipattern!.isEmpty) return;

      // 1. Pre-Check: Is this actually a Location Error?
      if (_namingHelper.shouldYieldToLocationLint(className, actualComponent)) {
        return;
      }

      // 2. Antipattern Check
      if (NamingUtils.validateName(name: className, template: rule.antipattern!)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [className, actualComponent.label],
        );
      }
    });
  }
}
