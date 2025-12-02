// lib/src/utils/ast/ast_utils.dart

import 'package:analyzer/dart/ast/ast.dart';

/// A utility class for common AST (Abstract Syntax Tree) traversal tasks.
class AstUtils {
  const AstUtils._();

  /// A robust helper to get the [TypeAnnotation] AST node from any kind of [FormalParameter].
  ///
  /// This method correctly unwraps parameters with default values and handles
  /// special cases like function-typed parameters.
  ///
  /// Note: For parameters that do not have an explicit type annotation on the
  /// parameter itself (e.g., `this.field` or `super.name`), this method
  /// correctly returns `null`, as the type is inferred from the field or
  /// super-constructor and is not part of the parameter's AST node.
  static TypeAnnotation? getParameterTypeNode(FormalParameter parameter) {
    // Handle all common, simple parameter types.
    if (parameter is SimpleFormalParameter) return parameter.type;
    if (parameter is FieldFormalParameter) return parameter.type;
    if (parameter is SuperFormalParameter) return parameter.type;

    // Handle function-typed parameters, where the type is on the `returnType` property.
    if (parameter is FunctionTypedFormalParameter) return parameter.returnType;

    // Recurse into wrapped parameters (like those with default values) to find the core parameter.
    if (parameter is DefaultFormalParameter) return getParameterTypeNode(parameter.parameter);

    return null;
  }
}
