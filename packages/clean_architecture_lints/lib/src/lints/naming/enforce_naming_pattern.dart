import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/naming_strategy_helper.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes follow the required syntactic naming pattern (e.g., `{{name}}Model`).
class EnforceNamingPattern extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_naming_pattern',
    problemMessage: 'The name `{0}` does not match the required `{1}` convention for a {2}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final NamingStrategyHelper _namingHelper;

  EnforceNamingPattern({required super.config, required super.layerResolver})
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

      // 1. Pre-Check: Is this actually a Location Error?
      if (_namingHelper.shouldYieldToLocationLint(className, actualComponent)) {
        return;
      }

      // 2. Pattern Check
      if (!NamingUtils.validateName(name: className, template: rule.pattern)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [className, rule.pattern, actualComponent.label],
        );
      }
    });
  }
}