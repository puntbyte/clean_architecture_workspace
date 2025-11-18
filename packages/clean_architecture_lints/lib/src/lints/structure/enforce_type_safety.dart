// lib/srcs/lints/structure/enforce_type_safety.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/type_safeties_config.dart';
import 'package:clean_architecture_lints/src/utils/ast_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A powerful lint that enforces strong types in method signatures, migrating
/// away from unsafe primitives based on the `type_safeties` configuration.
class EnforceTypeSafety extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_type_safety',
    problemMessage: 'Architectural type safety violation.', // Message is generated dynamically.
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTypeSafety({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (config.typeSafeties.rules.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      final component = layerResolver.getComponent(
        resolver.source.fullName,
        className: node.parent is ClassDeclaration
            ? (node.parent as ClassDeclaration?)?.name.lexeme
            : null,
      );
      if (component == ArchComponent.unknown) return;

      final componentId = component.id;

      // Filter to get only the rules that apply to the current component.
      final applicableRules = config.typeSafeties.rules.where(
        (rule) => rule.on.contains(componentId),
      );
      if (applicableRules.isEmpty) return;

      // Separate rules by what they check.
      final returnRules = applicableRules.where((r) => r.target == TypeSafetyTarget.return$);
      final paramRules = applicableRules.where((r) => r.target == TypeSafetyTarget.parameter);

      for (final rule in returnRules) {
        _validateReturnType(node, rule, reporter);
      }
      for (final rule in paramRules) {
        _validateParameters(node, rule, reporter);
      }
    });
  }

  void _validateReturnType(
    MethodDeclaration node,
    TypeSafetyRule rule,
    DiagnosticReporter reporter,
  ) {
    final element = node.declaredFragment?.element;
    if (element is ConstructorElement || element is SetterElement) return;

    final returnTypeNode = node.returnType;
    if (returnTypeNode == null) return;

    // Check if the return type's source text starts with the unsafe type.
    final returnTypeSource = returnTypeNode.toSource();
    if (returnTypeSource.startsWith(rule.unsafeType)) {
      reporter.atNode(
        returnTypeNode,
        LintCode(
          name: 'unsafe_return_type',
          problemMessage: 'The return type should be `${rule.safeType}`, not `${rule.unsafeType}`.',
          correctionMessage: 'Consider refactoring to use the safer `${rule.safeType}` type.',
        ),
      );
    }
  }

  void _validateParameters(
    MethodDeclaration node,
    TypeSafetyRule rule,
    DiagnosticReporter reporter,
  ) {
    for (final parameter in node.parameters?.parameters ?? <FormalParameter>[]) {
      final paramName = parameter.name?.lexeme;
      final typeNode = AstUtils.getParameterTypeNode(parameter);
      if (paramName == null || typeNode == null) continue;

      // If an identifier is specified, the parameter name must match.
      if (rule.identifier != null) {
        if (!paramName.toLowerCase().contains(rule.identifier!.toLowerCase())) {
          continue;
        }
      }

      // Check if the parameter's type source text starts with the unsafe type.
      final typeSource = typeNode.toSource();
      if (typeSource.startsWith(rule.unsafeType)) {
        reporter.atNode(
          typeNode,
          LintCode(
            name: 'unsafe_parameter_type',
            problemMessage:
                'The parameter `$paramName` should be of type `${rule.safeType}`, not '
                '`${rule.unsafeType}`.',
          ),
        );
      }
    }
  }
}
