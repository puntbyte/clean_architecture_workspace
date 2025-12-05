import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/lints/naming/base/naming_base_rule.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class NamingAntipatternRule extends NamingBaseRule with NamingLogic {
  static const _code = LintCode(
    name: 'arch_naming_antipattern',
    problemMessage: 'The name "{0}" is forbidden for a {1}.',
    correctionMessage:
        'Rename the class. The pattern "{2}" is explicitly banned to avoid confusion.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const NamingAntipatternRule() : super(code: _code);

  @override
  void checkName({
    required ClassDeclaration node,
    required ComponentConfig component,
    required DiagnosticReporter reporter,
    required ArchitectureConfig config,
  }) {
    if (component.antipatterns.isEmpty) return;

    final className = node.name.lexeme;

    for (final antipattern in component.antipatterns) {
      if (validateName(className, antipattern)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [
            className,
            component.displayName,
            antipattern,
          ],
        );
        break;
      }
    }
  }
}
