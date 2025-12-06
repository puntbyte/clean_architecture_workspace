import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/enums/exception_operation.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/exception_config.dart';
import 'package:architecture_lints/src/lints/safety/base/exception_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ExceptionForbiddenRule extends ExceptionBaseRule {
  static const _code = LintCode(
    name: 'arch_exception_forbidden',
    problemMessage: 'Forbidden Operation: "{0}".',
    correctionMessage: 'This architectural layer is not allowed to perform this operation.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ExceptionForbiddenRule() : super(code: _code);

  @override
  void checkMethod({
    required MethodDeclaration node,
    required List<ExceptionConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
  }) {
    for (final rule in rules) {
      for (final constraint in rule.forbidden) {
        if (constraint.operation == ExceptionOperation.throw$) {
          final throws = findNodes<ThrowExpression>(node.body);
          for (final t in throws) {
            final type = t.expression.staticType;
            final matchesSpecific = matchesType(
              type,
              constraint.definition,
              constraint.type,
              config.definitions,
            );
            final genericBan = constraint.definition == null && constraint.type == null;

            if (matchesSpecific || genericBan) {
              reporter.atNode(t, _code, arguments: ['throw ${type?.getDisplayString() ?? ''}']);
            }
          }
        }

        if (constraint.operation == ExceptionOperation.rethrow$) {
          final rethrows = findNodes<RethrowExpression>(node.body);
          if (rethrows.isNotEmpty) {
            reporter.atNode(rethrows.first, _code, arguments: ['rethrow']);
          }
        }
      }
    }
  }
}
