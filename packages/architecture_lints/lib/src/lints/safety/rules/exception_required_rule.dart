import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/enums/exception_operation.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/exception_config.dart';
import 'package:architecture_lints/src/lints/safety/base/exception_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ExceptionRequiredRule extends ExceptionBaseRule {
  static const _code = LintCode(
    name: 'arch_exception_missing',
    problemMessage: 'Missing Required Logic: "{0}".',
    correctionMessage: 'This component MUST implement the required error handling flow.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ExceptionRequiredRule() : super(code: _code);

  @override
  void checkMethod({
    required MethodDeclaration node,
    required List<ExceptionConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
  }) {
    final tryStatements = findNodes<TryStatement>(node.body);

    for (final rule in rules) {
      for (final constraint in rule.required) {
        if (constraint.operation == null) continue;

        var satisfied = false;

        switch (constraint.operation!) {
          case ExceptionOperation.tryReturn:
            // Must have a return inside a try block
            satisfied = tryStatements.any((t) => findNodes<ReturnStatement>(t.body).isNotEmpty);

          case ExceptionOperation.catchReturn:
            // Must have a return inside a catch block
            satisfied = tryStatements.any((t) {
              return t.catchClauses.any((c) => findNodes<ReturnStatement>(c.body).isNotEmpty);
            });

          case ExceptionOperation.catchThrow:
            // Must throw inside a catch block
            satisfied = tryStatements.any((t) {
              return t.catchClauses.any((c) => findNodes<ThrowExpression>(c.body).isNotEmpty);
            });

          // 'throw' and 'rethrow' are rarely "Required" in structure,
          // usually they are forbidden or flow-based.
          case ExceptionOperation.throw$:
          case ExceptionOperation.rethrow$:
            // If user puts 'throw' in required, we assume satisfied if ANY throw exists?
            // Or just ignore it for now.
            satisfied = true;
        }

        if (!satisfied) {
          reporter.atToken(
            node.name,
            _code,
            // Use the readable description from the Enum
            arguments: [constraint.operation!.description],
          );
        }
      }
    }
  }
}
