// lib/src/lints/error_handling/enforce_try_catch_in_repository.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that ensures calls to a DataSource within a repository are wrapped in a try-catch block.
///
/// **Reasoning:** DataSources interact with external systems (network, DB) and can throw
/// exceptions. The Repository is the architectural boundary responsible for catching these
/// exceptions and converting them into domain failures. Calls to data sources outside of
/// a `try` block indicate a potential crash risk.
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
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule only applies to repository implementations.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    context.registry.addMethodInvocation((node) {
      // 1. Identify the type of the object being called.
      final targetType = node.target?.staticType ?? node.realTarget?.staticType;
      if (targetType == null) return;

      final element = targetType.element;
      if (element == null) return;

      // 2. Determine if that type is defined in a DataSource file.
      final source = element.library?.firstFragment.source;
      if (source == null) return;

      final targetComponent = layerResolver.getComponent(source.fullName);

      // We check if the target class is a DataSource (interface or implementation).
      // Note: Adjust these enum checks if you have updated ArchComponent to just use .source
      if (targetComponent == ArchComponent.sourceInterface ||
          targetComponent == ArchComponent.sourceImplementation ||
          targetComponent == ArchComponent.source) {
        // 3. Check if the call is inside a valid try-catch block.
        if (!_isInsideTryBlock(node)) {
          reporter.atNode(node, _code);
        }
      }
    });
  }

  /// Checks if [node] is a descendant of the `body` of a [TryStatement].
  ///
  /// Merely having a TryStatement ancestor is not enough; the call must be
  /// inside the `try { ... }` block, not the `catch` or `finally` blocks.
  bool _isInsideTryBlock(MethodInvocation node) {
    final tryStatement = node.thisOrAncestorOfType<TryStatement>();
    if (tryStatement == null) return false;

    // Check if the node is physically inside the 'try' block range.
    final tryBody = tryStatement.body;
    return node.offset >= tryBody.offset && node.end <= tryBody.end;
  }
}
