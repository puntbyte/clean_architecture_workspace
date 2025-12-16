import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/engines/expression/expression.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/constants/regexps.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:architecture_lints/src/utils/token_syntax.dart';
import 'package:expressions/expressions.dart';

class ExpressionEngine {
  final ExpressionEvaluator _evaluator;
  final Map<String, dynamic> rootContext;

  ExpressionEngine({
    required AstNode node,
    required ArchitectureConfig config,
  }) : _evaluator = evaluator(),
      rootContext = _rootContext(node, config);

  static ExpressionEvaluator evaluator() => ExpressionEvaluator(
    memberAccessors: [
      // Wrappers
      MethodWrapper.accessor,
      ParameterWrapper.accessor,
      NodeWrapper.accessor,
      TypeWrapper.accessor,
      StringWrapper.accessor,
      GenericWrapper.accessor,

      // Collections
      ListWrapper.accessor,

      // Configuration Objects
      ConfigWrapper.accessor,

      // Default Map support
      MemberAccessor.mapAccessor,
    ],
  );

  static Map<String, dynamic> _rootContext(AstNode sourceNode, ArchitectureConfig config) => {
    'source': NodeWrapper.create(sourceNode, config.definitions),
    'config': ConfigWrapper(config),
    'definitions': config.definitions,
  };

  dynamic evaluate(String input, Map<String, dynamic> context) {
    // 1. Interpolation: "prefix_{{expr}}_suffix"
    if (input.contains(TokenSyntax.open)) {
      return input.replaceAllMapped(RegexConstants.interpolation, (match) {
        final expr = match.group(1);
        if (expr == null) return '';

        // Evaluate the inner expression
        final result = _evalRaw(expr.trim(), context);

        // Unwrap to string for the replacement
        return unwrap(result).toString();
      });
    }

    // 2. Pure Expression or Literal
    try {
      return _evalRaw(input, context);
    } catch (e) {
      // 3. Fallback: Literal String
      return input;
    }
  }

  dynamic _evalRaw(String expr, Map<String, dynamic> context) {
    final combinedContext = {...rootContext, ...context};
    try {
      final expression = Expression.parse(expr);
      return _evaluator.eval(expression, combinedContext);
    } catch (e) {
      // Rethrow to let evaluate() handle fallback or caller handle error
      rethrow;
    }
  }

  dynamic unwrap(dynamic value) {
    if (value == null) return null;

    if (value is TypeDefinition) return value.toMap();

    if (value is StringWrapper) return value.value;
    if (value is String || value is bool || value is num) return value;
    if (value is TypeWrapper) return unwrap(value.toMap());
    if (value is NodeWrapper) return unwrap(value.toMap());

    if (value is Iterable && value is! Map) return value.map(unwrap).toList();

    if (value is Map) return value.map((key, value) => MapEntry(key.toString(), unwrap(value)));

    return value.toString();
  }
}
