// lib/src/lints/error_handling/disallow_throwing_from_repository.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/component_kind.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowThrowingFromRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_throwing_from_repository',
    problemMessage: 'Do not throw exceptions from a repository. Return a Failure object instead.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowThrowingFromRepository({
    required super.config,
    required super.componentResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = componentResolver.resolveComponent(resolver.source.fullName);

    if (component?.kind != ComponentKind.repositoryImplementation) return;

    context.registry.addThrowExpression((node) => reporter.atNode(node, _code));
  }
}
