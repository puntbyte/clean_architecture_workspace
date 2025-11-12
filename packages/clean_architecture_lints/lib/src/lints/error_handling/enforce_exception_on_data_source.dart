// lib/srcs/lints/error_handling/enforce_exception_on_data_source.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/component_kind.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that DataSource methods throw exceptions on failure, not return wrapper types.
class EnforceExceptionOnDataSource extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_exception_on_data_source',
    problemMessage: 'DataSources should throw exceptions on failure, not return Result/Either types.',
    correctionMessage: 'Change the return type to a simple Future and throw a specific Exception instead.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceExceptionOnDataSource({
    required super.config,
    required super.componentResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = componentResolver.resolveComponent(resolver.source.fullName);

    // The lint applies to both the interface and the implementation of a data source.
    final isDataSource = component?.kind == ComponentKind.sourceContract ||
        component?.kind == ComponentKind.sourceImplementation;

    if (!isDataSource) {
      return;
    }

    // Get the list of "special" return types from the central type_safety config.
    final forbiddenReturnTypes = config.typeSafety.returns.map((rule) => rule.type).toSet();
    if (forbiddenReturnTypes.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      final returnTypeNode = node.returnType;
      if (returnTypeNode == null) return;

      final returnTypeName = returnTypeNode.toSource().split('<').first;

      if (forbiddenReturnTypes.contains(returnTypeName)) {
        reporter.atNode(returnTypeNode, _code);
      }
    });
  }
}
