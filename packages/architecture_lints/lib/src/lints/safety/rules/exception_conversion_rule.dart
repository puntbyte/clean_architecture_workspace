import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/exception_config.dart';
import 'package:architecture_lints/src/lints/safety/base/exception_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ExceptionConversionRule extends ExceptionBaseRule {
  static const _code = LintCode(
    name: 'arch_exception_conversion',
    problemMessage: 'Incorrect Error Conversion: Must convert "{0}" to "{1}".',
    correctionMessage: 'Ensure the catch block returns the correct Domain Failure.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ExceptionConversionRule() : super(code: _code);

  @override
  void checkCatch({
    required CatchClause node,
    required List<ExceptionConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
  }) {
    final caughtType = getCaughtType(node);
    if (caughtType == null) return; // Untyped catch (catch(e)), cannot enforce specific conversion

    for (final rule in rules) {
      _checkConversion(node, caughtType, rule, config, reporter);
    }
  }

  void _checkConversion(
    CatchClause node,
    DartType caughtType,
    ExceptionConfig rule,
    ArchitectureConfig config,
    DiagnosticReporter reporter,
  ) {
    for (final conversion in rule.conversions) {
      // 1. Does the caught exception match the 'from' rule?
      if (matchesType(caughtType, conversion.fromDefinition, null, config.definitions)) {
        // 2. Scan return statements in this catch block
        final returns = findNodes<ReturnStatement>(node.body);

        if (returns.isEmpty) continue;

        // 3. Verify at least one return matches the 'to' rule
        final hasValidReturn = returns.any(
          (r) => returnStatementMatchesType(r, conversion.toDefinition, config.definitions),
        );

        if (!hasValidReturn) {
          // Resolve human readable names
          final fromName =
              config.definitions[conversion.fromDefinition]?.type ?? conversion.fromDefinition;
          final toName =
              config.definitions[conversion.toDefinition]?.type ?? conversion.toDefinition;

          reporter.atNode(
            node.exceptionType ?? node,
            _code,
            arguments: [fromName, toName],
          );
        }
      }
    }
  }
}
