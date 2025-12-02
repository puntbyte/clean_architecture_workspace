// lib/src/lints/purity/enforce_contract_api.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints_old/architecture_lint_rule.dart';
import 'package:architecture_lints/src/utils_old/ast/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceContractApi extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_contract_api',
    problemMessage: 'The public member `{0}` is not defined in the interface contract.',
    correctionMessage:
        'Make this member private (prefix with `_`) or add it to the interface contract.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceContractApi({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);

    // Only enforce on implementations that are expected to follow a strict contract.
    if (component != ArchComponent.repository && component != ArchComponent.sourceImplementation) {
      return;
    }

    context.registry.addClassDeclaration((classNode) {
      if (classNode.abstractKeyword != null) return;

      for (final member in classNode.members) {
        _validateMember(member, reporter);
      }
    });
  }

  void _validateMember(ClassMember member, DiagnosticReporter reporter) {
    ExecutableElement? element;
    Token? nameToken;

    if (member is MethodDeclaration) {
      // [Analyzer 8.0.0 Fix] Use declaredFragment
      element = member.declaredFragment?.element;
      nameToken = member.name;
    } else if (member is FieldDeclaration) {
      final fieldVar = member.fields.variables.firstOrNull;
      final fieldElement = fieldVar?.declaredFragment?.element;
      if (fieldElement is PropertyInducingElement) {
        element = fieldElement.getter;
        nameToken = fieldVar?.name;
      }
    }

    if (element == null || nameToken == null) return;

    // Skip private members, static members, and constructors
    if (element.isPrivate || element.isStatic || element is ConstructorElement) return;

    // Check if this member overrides a member from a Port/Contract interface
    if (!SemanticUtils.isArchitecturalOverride(element, layerResolver)) {
      reporter.atToken(nameToken, _code, arguments: [nameToken.lexeme]);
    }
  }
}
