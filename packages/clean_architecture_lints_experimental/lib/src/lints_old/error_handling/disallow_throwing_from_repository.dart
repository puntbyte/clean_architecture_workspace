// lib/src/lints/error_handling/disallow_throwing_from_repository.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids `throw` and `rethrow` expressions inside a repository implementation
/// based on the `error_handlers` configuration.
///
/// **Category:** Error Handling
///
/// **Reasoning:** Repositories act as a "Boundary". They are responsible for catching
/// exceptions from the Data Source and converting them into a `Failure` object (typically
/// wrapped in an `Either`). Throwing or rethrowing exceptions breaks this boundary,
/// leaking infrastructure details into the Domain layer.
class DisallowThrowingFromRepository extends ArchitectureRule {
  static const _code = LintCode(
    name: 'disallow_throwing_from_repository',
    problemMessage:
        'Repositories should not throw or rethrow exceptions. Convert them to a Failure object.',
    correctionMessage: 'Wrap the operation in a try/catch block and return a Failure (Left).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowThrowingFromRepository({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // 1. Scope: Only runs on Repository Implementations
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    // 2. Config: Check Error Handler rules
    final rule = definition.errorHandlers.ruleFor(ArchComponent.repository);

    // Default behaviors if no config is provided (Strict Boundary)
    var forbidThrow = true;
    var forbidRethrow = true;

    if (rule != null) {
      // If config exists, we strictly follow the 'forbidden' operations list.
      // We flatten the list of operations from all forbidden rules.
      final forbiddenOps = rule.forbidden.expand((r) => r.operations).toSet();
      forbidThrow = forbiddenOps.contains('throw');
      forbidRethrow = forbiddenOps.contains('rethrow');
    }

    // 3. Check 'throw'
    if (forbidThrow) {
      context.registry.addThrowExpression((node) => reporter.atNode(node, _code));
    }

    // 4. Check 'rethrow'
    if (forbidRethrow) {
      context.registry.addRethrowExpression((node) => reporter.atNode(node, _code));
    }
  }
}
