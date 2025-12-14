import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/actions/context/wrappers/config_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/generic_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/method_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/node_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/parameter_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:expressions/expressions.dart';

class ExpressionEngine {
  final ExpressionEvaluator _evaluator;
  final Map<String, dynamic> rootContext;
  final RegExp _interpolationRegex = RegExp(r'\$\{([^}]+)\}');

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
    if (input.contains(r'${')) {
      return input.replaceAllMapped(_interpolationRegex, (match) {
        final expr = match.group(1);
        if (expr == null) return '';
        final result = _evalRaw(expr, context);
        return unwrap(result).toString();
      });
    }

    try {
      return _evalRaw(input, context);
    } catch (e) {
      return input;
    }
  }

  dynamic _evalRaw(String expr, Map<String, dynamic> context) {
    final combinedContext = {...rootContext, ...context};
    final expression = Expression.parse(expr);
    return _evaluator.eval(expression, combinedContext);
  }

  dynamic unwrap(dynamic value) {
    if (value == null) return null;

    if (value is Definition) return value.toMap();

    if (value is StringWrapper) return value.value;
    if (value is String || value is bool || value is num) return value;
    if (value is TypeWrapper) return unwrap(value.toMap());
    if (value is NodeWrapper) return unwrap(value.toMap());

    if (value is Iterable && value is! Map) return value.map(unwrap).toList();

    if (value is Map) return value.map((key, value) => MapEntry(key.toString(), unwrap(value)));

    return value.toString();
  }
}
