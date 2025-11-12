// lib/src/utils/ast_utils.dart

import 'package:analyzer/dart/ast/ast.dart';

/// A utility class for common AST (Abstract Syntax Tree) traversal tasks.
class AstUtils {
  const AstUtils._();

  /// A robust helper to get the `TypeAnnotation` AST node from any kind of `FormalParameter`.
  ///
  /// This is useful for visitors that need to inspect the syntactic type of a parameter.
  static TypeAnnotation? getParameterTypeNode(FormalParameter parameter) {
    if (parameter is SimpleFormalParameter) return parameter.type;
    if (parameter is FieldFormalParameter) return parameter.type;
    if (parameter is SuperFormalParameter) return parameter.type;
    // Recurse into the nested parameter (e.g., inside `required String name`).
    if (parameter is DefaultFormalParameter) return getParameterTypeNode(parameter.parameter);
    return null;
  }
}
