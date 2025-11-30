// lib/src/lints/error_handling/enforce_try_catch_in_repository.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that ensures calls to a DataSource within a repository are wrapped in a try-catch block.
///
/// This lint is driven by the `error_handlers` configuration. If a component is configured
/// to require `try_return`, this lint ensures that interactions with dependencies (like DataSources)
/// are safe.
class EnforceTryCatchInRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_try_catch_in_repository',
    problemMessage: 'Calls to a DataSource must be wrapped in a `try` block.',
    correctionMessage: 'Wrap this call in a try-catch block and return a Failure on error.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTryCatchInRepository({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final component = layerResolver.getComponent(resolver.source.fullName);

    // 1. Check Configuration
    // Does this component require try-catch blocks?
    if (!_requiresTryCatch(component)) return;

    context.registry.addMethodInvocation((node) {
      // 2. Identify Target
      final targetType = node.target?.staticType ?? node.realTarget?.staticType;
      if (targetType == null) return;

      final element = targetType.element;
      if (element == null) return;

      // [Analyzer 8.0.0 Fix] Use firstFragment.source
      final source = element.library?.firstFragment.source;
      if (source == null) return;

      // 3. Check Target Component
      // We specifically enforce this for interactions with DataSources.
      final targetComponent = layerResolver.getComponent(source.fullName);
      final isDataSource =
          targetComponent == ArchComponent.sourceInterface ||
          targetComponent == ArchComponent.sourceImplementation ||
          targetComponent == ArchComponent.source;

      if (isDataSource) {
        // 4. Safety Check
        if (!_isInsideTryBlock(node)) {
          reporter.atNode(node, _code);
        }
      }
    });
  }

  bool _requiresTryCatch(ArchComponent component) {
    final rule = config.errorHandlers.ruleFor(component);

    // Case A: Explicit Config exists.
    if (rule != null) {
      // Check if 'try_return' is in the required operations.
      // We look for the string 'try_return' in the operations list of any required rule.
      return rule.required.any((op) => op.operations.contains('try_return'));
    }

    // Case B: No Config (Default Behavior).
    // By default, we enforce this strictly on Repositories.
    return component == ArchComponent.repository;
  }

  bool _isInsideTryBlock(MethodInvocation node) {
    final tryStatement = node.thisOrAncestorOfType<TryStatement>();
    if (tryStatement == null) return false;

    // The call must be inside the `try { ... }` block, not `catch` or `finally`.
    final tryBody = tryStatement.body;
    return node.offset >= tryBody.offset && node.end <= tryBody.end;
  }
}
