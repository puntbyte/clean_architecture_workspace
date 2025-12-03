import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NamingPatternRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_naming_pattern',
    problemMessage: 'Class name does not match the architectural pattern "{0}".',
  );

  const NamingPatternRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    ComponentConfig? component,
  }) {
    // Skip if no patterns are defined for this component
    if (component == null || component.patterns.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      var hasMatch = false;

      // Logic: It must match AT LEAST ONE pattern.
      // e.g. If patterns are ['{{name}}Bloc', '{{name}}Cubit'],
      // 'UserBloc' matches (valid). 'UserCubit' matches (valid).
      for (final pattern in component.patterns) {
        if (NamingUtils.validateName(name: className, template: pattern)) {
          hasMatch = true;
          break;
        }
      }

      if (!hasMatch) {
        // Report error listing all allowed patterns joined by " OR "
        final allowedPatterns = component.patterns.join(' OR ');

        reporter.atToken(
          node.name,
          _code,
          arguments: [allowedPatterns],
        );
      }
    });
  }
}
