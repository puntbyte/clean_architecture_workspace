// lib/src/lints/purity/disallow_model_return_from_repository.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/ast/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DisallowModelReturnFromRepository extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_model_return_from_repository',
    problemMessage: 'Repository methods must return domain Entities, not data Models.',
    correctionMessage: 'Map the Model to an Entity before returning it from the repository.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final Set<String> _wrapperTypeNames;

  DisallowModelReturnFromRepository({
    required super.config,
    required super.layerResolver,
  }) : _wrapperTypeNames = {
         // 1. Collect all "Allowed Return Types" from config.
         // These are typically wrappers like FutureEither, Result, etc.
         ...config.typeSafeties.rules
             .expand((rule) => rule.allowed)
             .where((detail) => detail.kind == 'return' && detail.type != null)
             .map((detail) {
               // Resolve 'result.wrapper' -> 'FutureEither'
               final def = config.typeDefinitions.get(detail.type!);
               return def?.name ?? detail.type!;
             }),

         // 2. Add standard/fallback wrappers
         'Right',
         'Left',
         'Either',
         'Future',
         'FutureOr',
       },
       super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    context.registry.addReturnStatement((node) {
      final expression = node.expression;
      if (expression == null) return;

      final parentMethod = node.thisOrAncestorOfType<MethodDeclaration>();
      final methodElement = parentMethod?.declaredFragment?.element;

      if (methodElement == null || methodElement.isPrivate) return;

      if (SemanticUtils.isArchitecturalOverride(methodElement, layerResolver)) {
        // STRATEGY 1: Inspect Wrappers (Right(model), Success(model))
        if (expression is InstanceCreationExpression) {
          // Analyzer 8.0+: name2 for NamedType
          final typeName = expression.constructorName.type.name.lexeme;
          if (_isSuccessWrapper(typeName)) {
            final arg = expression.argumentList.arguments.firstOrNull;
            if (arg != null && _isModelType(arg.staticType)) {
              reporter.atNode(arg, _code);
              return;
            }
          }
        } else if (expression is MethodInvocation) {
          final name = expression.methodName.name;
          if (_isSuccessWrapper(name)) {
            final arg = expression.argumentList.arguments.firstOrNull;
            if (arg != null && _isModelType(arg.staticType)) {
              reporter.atNode(arg, _code);
              return;
            }
          }
        }

        // STRATEGY 2: Fallback to checking static type (implicit returns)
        final successType = _extractSuccessType(expression.staticType);
        if (_isModelType(successType)) {
          reporter.atNode(expression, _code);
        }
      }
    });
  }

  bool _isModelType(DartType? type) {
    return SemanticUtils.isComponent(type, layerResolver, ArchComponent.model);
  }

  bool _isSuccessWrapper(String name) {
    return name == 'Right' || name == 'Success' || name == 'value';
  }

  DartType? _extractSuccessType(DartType? type) {
    if (type is! InterfaceType) return type;

    final name = type.element.name;

    // Recursively unwrap known wrapper types
    if (_wrapperTypeNames.contains(name)) {
      if (type.typeArguments.isEmpty) return null;

      // Heuristic: Success type is usually the LAST argument
      // (Future<T>, Either<L, R>, Result<T>)
      return _extractSuccessType(type.typeArguments.last);
    }

    return type;
  }
}
