import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/lints/naming/base/naming_base_rule.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NamingPatternRule extends NamingBaseRule with NamingLogic {
  static const _code = LintCode(
    name: 'arch_naming_pattern',
    problemMessage: 'The {0} "{1}" does not follow the required naming convention.',
    correctionMessage: 'Rename it to match the pattern "{2}" (e.g., "{3}").',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const NamingPatternRule() : super(code: _code);

  @override
  void checkName({
    required ClassDeclaration node,
    required ComponentConfig component,
    required DiagnosticReporter reporter,
    required ArchitectureConfig config,
  }) {
    if (component.patterns.isEmpty) return;

    final className = node.name.lexeme;
    var hasAnyMatch = false;

    for (final pattern in component.patterns) {
      if (validateName(className, pattern)) {
        hasAnyMatch = true;
        break;
      }
    }

    if (!hasAnyMatch) {
      reporter.atToken(
        node.name,
        _code,
        arguments: [
          component.displayName,
          className,
          component.patterns.join('" or "'),
          generateExample(component.patterns.first),
        ],
      );
    }
  }
}
