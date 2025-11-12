// lib/srcs/lints/error_handling/enforce_try_catch_in_repository.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/component_kind.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';


/// Enforces that calls to a DataSource from within a Repository are wrapped in a try-catch block.
class EnforceTryCatchInRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_try_catch_in_repository',
    problemMessage: 'Calls to a DataSource must be wrapped in a try-catch block.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTryCatchInRepository({
    required super.config,
    required super.componentResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = componentResolver.resolveComponent(resolver.source.fullName);
    if (component?.kind != ComponentKind.repositoryImplementation) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      final targetType = node.target?.staticType;
      if (targetType == null) return;

      final targetSource = targetType.element?.firstFragment.libraryFragment?.source;
      if (targetSource == null) return;

      final targetComponent = componentResolver.resolveComponent(targetSource.fullName);
      if (targetComponent == null) return;

      // Is this a call on a DataSource?
      final isDataSourceCall = targetComponent.kind == ComponentKind.sourceContract ||
          targetComponent.kind == ComponentKind.sourceImplementation;

      if (isDataSourceCall) {
        // Is the call NOT inside a try block?
        if (node.thisOrAncestorOfType<TryStatement>() == null) {
          reporter.atNode(node, _code);
        }
      }
    });
  }
}
