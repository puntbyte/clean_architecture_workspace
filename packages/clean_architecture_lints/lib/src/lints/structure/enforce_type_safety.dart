// lib/src/lints/structure/enforce_type_safety.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/type_safeties_config.dart';
import 'package:clean_architecture_lints/src/utils/ast/ast_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces strong types in method signatures, migrating
/// away from unsafe primitives based on the `type_safeties` configuration.
class EnforceTypeSafety extends ArchitectureLintRule {
  static const _returnCode = LintCode(
    name: 'enforce_type_safety_return',
    problemMessage: 'The return type should be `{0}`, not `{1}`.',
    correctionMessage: 'Consider refactoring to use the safer `{0}` type.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );
  static const _parameterCode = LintCode(
    name: 'enforce_type_safety_parameter',
    problemMessage: 'The parameter `{0}` should be of type `{1}`, not `{2}`.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTypeSafety({required super.config, required super.layerResolver})
    : super(code: _returnCode);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (config.typeSafeties.rules.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      final parent = node.parent;
      final className = parent is ClassDeclaration ? parent.name.lexeme : null;
      final component = layerResolver.getComponent(resolver.source.fullName, className: className);
      if (component == ArchComponent.unknown) return;

      // Pre-filter rules to get only those applicable to this component.
      final applicableRules = config.typeSafeties.rulesFor(component.id);
      if (applicableRules.isEmpty) return;

      // Check return types
      _validateReturnType(node, applicableRules, reporter);

      // Check parameters
      _validateParameters(node, applicableRules, reporter);
    });
  }

  void _validateReturnType(
    MethodDeclaration node,
    List<TypeSafetyRule> rules,
    DiagnosticReporter reporter,
  ) {
    final returnTypeNode = node.returnType;
    if (returnTypeNode == null) return;

    final returnType = returnTypeNode.type;
    if (returnType == null) return;

    // [Analyzer 8.0.0] Access name safely
    final returnTypeName = returnType.element?.name ?? returnTypeNode.toSource();

    // Check against all applicable return rules.
    for (final rule in rules) {
      for (final detail in rule.returns) {
        // Use 'startsWith' or explicit check to handle generics if needed
        // e.g. unsafe: 'Future', safe: 'FutureEither'.
        // 'Future<void>' starts with 'Future'.
        if (returnTypeName == detail.unsafeType) {
          reporter.atNode(
            returnTypeNode,
            _returnCode,
            arguments: [detail.safeType, detail.unsafeType],
          );
          return; // Report once per return type.
        }
      }
    }
  }

  void _validateParameters(
    MethodDeclaration node,
    List<TypeSafetyRule> rules,
    DiagnosticReporter reporter,
  ) {
    if (node.parameters == null) return;

    for (final parameter in node.parameters!.parameters) {
      final paramName = parameter.name?.lexeme;
      final typeNode = AstUtils.getParameterTypeNode(parameter);
      final paramType = typeNode?.type;

      if (paramName == null || typeNode == null || paramType == null) continue;

      final paramTypeName = paramType.element?.name ?? typeNode.toSource();

      // Check against all applicable parameter rules.
      for (final rule in rules) {
        for (final detail in rule.parameters) {
          // Check if both the type and (if specified) the identifier match.
          if (paramTypeName == detail.unsafeType) {
            final identifierMatches =
                detail.identifier == null ||
                paramName.toLowerCase().contains(detail.identifier!.toLowerCase());

            if (identifierMatches) {
              reporter.atNode(
                typeNode,
                _parameterCode,
                arguments: [paramName, detail.safeType, detail.unsafeType],
              );
              // Break inner loops to report only once per parameter.
              break;
            }
          }
        }
      }
    }
  }
}
