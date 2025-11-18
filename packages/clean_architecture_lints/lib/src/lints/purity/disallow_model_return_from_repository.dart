// lib/srcs/lints/purity/disallow_model_return_from_repository.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids repository implementations from returning `Models` from overridden methods.
///
/// **Reasoning:** The repository is the boundary between the data and domain layers.
/// Its public contract must always be fulfilled with pure domain `Entities`. This lint
/// specifically checks the `return` statements inside a repository's methods to
/// ensure that a `Model` received from a `DataSource` is correctly mapped to an
/// `Entity` before being returned.
class DisallowModelReturnFromRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_model_return_from_repository',
    problemMessage: 'Repository methods must return domain Entities, not data Models.',
    correctionMessage: 'Map the Model to an Entity before returning it from the repository.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  /// A cached set of wrapper type names, built from the configuration.
  final Set<String> _wrapperTypeNames;

  DisallowModelReturnFromRepository({required super.config, required super.layerResolver})
      : _wrapperTypeNames = {
    // Get all configured "safe" return types from the central config.
    ...config.typeSafeties.rules
        .expand((rule) => rule.returns)
        .map((detail) => detail.safeType),
    // Also include common implementation wrappers like `Right` from fpdart.
    'Right',
  },
        super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule only applies to files identified as repository implementations.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    context.registry.addReturnStatement((node) {
      final expression = node.expression;
      if (expression == null) return;

      final parentMethod = node.thisOrAncestorOfType<MethodDeclaration>();
      final methodElement = parentMethod?.declaredFragment?.element;
      if (methodElement == null || methodElement.isPrivate) return;

      // Only lint returns from methods that are actually overriding a domain contract.
      if (SemanticUtils.isArchitecturalOverride(methodElement, layerResolver)) {
        // Unwrap the return type to find the core "success" value.
        final successType = _extractSuccessType(expression.staticType);

        // Check if that core value is a Model.
        if (SemanticUtils.isComponent(successType, layerResolver, ArchComponent.model)) {
          reporter.atNode(expression, _code);
        }
      }
    });
  }

  /// Recursively unwraps a type (e.g., `Future<Either<L, R>>` or `Right<R>`) to get `R`,
  /// using the centrally configured wrapper types for maximum flexibility.
  DartType? _extractSuccessType(DartType? type) {
    if (type is! InterfaceType) return type;

    final name = type.element.name;

    // Always unwrap Future/FutureOr — they are universal in repository contracts
    if (name == 'Future' || name == 'FutureOr') {
      return type.typeArguments.isEmpty
          ? null
          : _extractSuccessType(type.typeArguments.single);
    }

    // Configurable wrappers (Either, Right, Result, etc.)
    if (_wrapperTypeNames.contains(name)) {
      return type.typeArguments.isEmpty
          ? null
          : _extractSuccessType(type.typeArguments.last);
    }

    return type;
  }
}
