// lib/src/engines/expression/expression_engine.dart

import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/engines/expression/expression.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
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
      // 1. Wrappers
      MethodWrapper.accessor,
      ParameterWrapper.accessor,
      FieldWrapper.accessor,
      NodeWrapper.accessor,
      TypeWrapper.accessor,
      StringWrapper.accessor,
      GenericWrapper.accessor,

      // 2. Standard Dart String Accessor (FIXES THE ERROR)
      // This allows calling .replace, .substring, etc., on results of casing properties
      const MemberAccessor<String>.fallback(_getStringMethod),

      // 3. Collections & Config
      ListWrapper.accessor,
      ConfigWrapper.accessor,

      // 4. Defaults
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
    if (input.contains(TokenSyntax.open)) return _evaluateInterpolation(input, context);

    // 2. Pure Expression or Literal
    try {
      return _evalRaw(input, context);
    } catch (e) {
      // 3. Fallback: Literal String
      return input;
    }
  }

  /// Parses and evaluates expressions inside TokenSyntax blocks.
  String _evaluateInterpolation(String input, Map<String, dynamic> context) {
    final buffer = StringBuffer();
    const open = TokenSyntax.open;
    const close = TokenSyntax.close;
    const openLen = open.length;
    const closeLen = close.length;

    var i = 0;
    while (i < input.length) {
      if (input.startsWith(open, i)) {
        final contentStart = i + openLen;
        final contentEnd = _findClosingBrace(input, contentStart);

        if (contentEnd != -1) {
          final expr = input.substring(contentStart, contentEnd);
          try {
            final result = _evalRaw(expr.trim(), context);
            // FIX: Use toString() directly. Do NOT use unwrap() here.
            // StringWrapper.toString() returns the value.
            // unwrap() converts it to a Map, which we don't want inside a string.
            buffer.write(result.toString());
          } catch (e) {
            buffer.write('$open$expr$close');
          }
          i = contentEnd + closeLen;
          continue;
        }
      }
      buffer.write(input[i]);
      i++;
    }

    return buffer.toString();
  }

  /// Finds the index of the closing token that matches the opening token used before [startIndex].
  /// Respects nested tokens and string literals.
  int _findClosingBrace(String input, int startIndex) {
    var depth = 0;
    String? quoteChar; // ' or "

    const open = TokenSyntax.open;
    const close = TokenSyntax.close;
    const openLen = open.length;
    const closeLen = close.length;

    for (var i = startIndex; i < input.length; i++) {
      final char = input[i];

      // 1. Handle Quotes (Skip content inside strings)
      if (quoteChar != null) {
        if (char == r'\') {
          i++; // Skip escaped char
        } else if (char == quoteChar) {
          quoteChar = null; // Close quote
        }
        continue;
      } else if (char == "'" || char == '"') {
        quoteChar = char;
        continue;
      }

      // 2. Handle Nested Tokens
      // Check Open Token first
      if (input.startsWith(open, i)) {
        depth++;
        i += openLen - 1; // Skip ahead
        continue;
      }

      // Check Close Token
      if (input.startsWith(close, i)) {
        if (depth > 0) {
          depth--;
          i += closeLen - 1; // Skip ahead
        } else {
          // Found matching close at depth 0
          return i;
        }
      }
    }
    return -1; // Unbalanced
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

    // 1. Unwrap Wrappers to Primitives / Maps
    if (value is StringWrapper) return value.value; // Return String
    if (value is TypeWrapper) return value.toMap(); // Return Map
    if (value is NodeWrapper) return value.toMap(); // Return Map (important for templates)

    // TypeDefinition stays a Map because it's a data object, not a string
    if (value is TypeDefinition) return value.toMap();

    // 2. Primitives
    if (value is String || value is bool || value is num) return value;

    // 3. Collections
    if (value is Iterable && value is! Map) return value.map(unwrap).toList();

    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), unwrap(v)));

    return value.toString();
  }

  /// Helper to map common Dart String methods to the evaluator
  static dynamic _getStringMethod(String obj, String name) => switch (name) {
    // FIX: Accept dynamic args and toString() them to handle Wrappers
    'replace' => (dynamic from, dynamic replace) => obj.replaceAll(
      from.toString(),
      replace.toString(),
    ),

    'replaceAll' => (dynamic from, dynamic replace) => obj.replaceAll(
      from.toString(),
      replace.toString(),
    ),

    'contains' => (dynamic other) => obj.contains(other.toString()),
    'startsWith' => (dynamic other) => obj.startsWith(other.toString()),
    'endsWith' => (dynamic other) => obj.endsWith(other.toString()),

    'substring' => obj.substring,
    'toLowerCase' => obj.toLowerCase,
    'toUpperCase' => obj.toUpperCase,
    'trim' => obj.trim,
    'length' => obj.length,
    _ => throw ArgumentError('Method "$name" not supported on String in expressions'),
  };
}
