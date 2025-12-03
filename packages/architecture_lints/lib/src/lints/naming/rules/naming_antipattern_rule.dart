import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NamingAntipatternRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_naming_antipattern',
    problemMessage: 'The name "{0}" matches a forbidden pattern for this component.',
    correctionMessage: 'Rename the class to avoid the pattern "{1}".',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const NamingAntipatternRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    ComponentConfig? component,
  }) {
    // Skip if no antipatterns are defined
    if (component == null || component.antipatterns.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      // Logic: It must NOT match ANY antipattern.
      for (final antipattern in component.antipatterns) {
        if (NamingUtils.validateName(name: className, template: antipattern)) {

          reporter.atToken(
            node.name,
            _code,
            arguments: [className, antipattern],
          );

          // Stop after finding the first violation to avoid spamming multiple warnings
          // for the same class if it matches multiple antipatterns.
          break;
        }
      }
    });
  }
}