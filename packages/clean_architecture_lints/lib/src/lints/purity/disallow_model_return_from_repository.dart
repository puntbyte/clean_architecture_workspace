// lib/src/lints/purity/disallow_model_return_from_repository.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowModelReturnFromRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_model_return_from_repository',
    problemMessage: 'Repository methods must return domain Entities, not data Models.',
    correctionMessage: 'Map the Model to an Entity before returning it from the repository.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final Set<String> _wrapperTypeNames;

  DisallowModelReturnFromRepository({required super.config, required super.layerResolver})
      : _wrapperTypeNames = {
    ...config.typeSafeties.rules
        .expand((rule) => rule.returns)
        .map((detail) => detail.safeType),
    'Right',
    'Left',
    'Either',
  },
        super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    context.registry.addReturnStatement((node) {
      final expression = node.expression;
      if (expression == null) return;

      final parentMethod = node.thisOrAncestorOfType<MethodDeclaration>();
      final methodElement = parentMethod?.declaredFragment?.element;

      if (methodElement == null || methodElement.isPrivate) return;

      if (SemanticUtils.isArchitecturalOverride(methodElement, layerResolver)) {

        // STRATEGY 1: Inspect AST for Wrapper Constructors (e.g., Right(model))
        // This bypasses type inference upcasting by looking at the argument directly.
        if (expression is InstanceCreationExpression) {
          final typeName = expression.constructorName.type.name2.lexeme;
          if (_isSuccessWrapper(typeName)) {
            final arg = expression.argumentList.arguments.firstOrNull;
            // Check the static type of the argument (e.g., `model`), which is still `UserModel`.
            if (arg != null && SemanticUtils.isComponent(arg.staticType, layerResolver, ArchComponent.model)) {
              reporter.atNode(arg, _code);
              return;
            }
          }
        }
        // Handle MethodInvocation wrappers (e.g., right(model) or Future.value(model))
        else if (expression is MethodInvocation) {
          final name = expression.methodName.name;
          if (_isSuccessWrapper(name)) {
            final arg = expression.argumentList.arguments.firstOrNull;
            if (arg != null && SemanticUtils.isComponent(arg.staticType, layerResolver, ArchComponent.model)) {
              reporter.atNode(arg, _code);
              return;
            }
          }
        }

        // STRATEGY 2: Fallback to checking the expression's static type
        // This handles cases like `return model;` or `return futureModel;`.
        final successType = _extractSuccessType(expression.staticType);

        if (SemanticUtils.isComponent(successType, layerResolver, ArchComponent.model)) {
          reporter.atNode(expression, _code);
        }
      }
    });
  }

  /// Heuristic to identify wrappers that imply success/returning data.
  bool _isSuccessWrapper(String name) {
    // 'Right' is standard FP. 'value' handles Future.value().
    return name == 'Right' || name == 'Success' || name == 'value';
  }

  DartType? _extractSuccessType(DartType? type) {
    if (type is! InterfaceType) return type;

    final name = type.element.name;

    if (name == 'Future' || name == 'FutureOr') {
      return type.typeArguments.isEmpty
          ? null
          : _extractSuccessType(type.typeArguments.single);
    }

    if (_wrapperTypeNames.contains(name)) {
      // Assumes the success type is the LAST type argument (standard for Either/Result)
      return type.typeArguments.isEmpty
          ? null
          : _extractSuccessType(type.typeArguments.last);
    }

    return type;
  }
}