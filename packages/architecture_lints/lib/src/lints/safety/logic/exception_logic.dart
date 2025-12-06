import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';

mixin ExceptionLogic {
  /// Checks if the given [type] matches a definition alias or raw type name.
  bool matchesType(
    DartType? type,
    String? definitionKey,
    String? rawType,
    Map<String, Definition> registry,
  ) {
    if (type == null) return false;
    final name = type.element?.name ?? '';

    // 1. Raw Type Check
    if (rawType != null && name == rawType) {
      return true;
    }

    // 2. Definition Check
    if (definitionKey != null) {
      final def = registry[definitionKey];
      if (def != null && def.type == name) {
        if (def.import != null) {
          // Compatibility with newer analyzer fragments
          final libUri = type.element?.library?.firstFragment.source.uri.toString();
          if (libUri == def.import) return true;
        } else {
          return true;
        }
      }
    }

    return false;
  }

  /// Helper to traverse a method body and find nodes of specific types.
  List<T> findNodes<T extends AstNode>(AstNode root) {
    final results = <T>[];
    root.visitChildren(_TypedVisitor<T>(results));
    return results;
  }

  /// Resolves the type of exception caught in a CatchClause.
  /// Returns null if not explicitly typed (e.g., 'catch (e)').
  DartType? getCaughtType(CatchClause node) {
    return node.exceptionType?.type;
  }

  /// Checks if a return statement returns a specific type (deep check).
  /// e.g. return Left(ServerFailure()) matches 'failure.server'.
  bool returnStatementMatchesType(
    ReturnStatement node,
    String definitionKey,
    Map<String, Definition> registry,
  ) {
    final expression = node.expression;
    if (expression == null) return false;

    final returnType = expression.staticType;

    // Direct match: return ServerFailure();
    if (matchesType(returnType, definitionKey, null, registry)) return true;

    // Wrapped match (Recursion for Either/Result types): return Left(ServerFailure());
    // We check the type arguments of the wrapper.
    if (returnType is InterfaceType) {
      for (final arg in returnType.typeArguments) {
        if (matchesType(arg, definitionKey, null, registry)) return true;
      }
    }

    return false;
  }
}

class _TypedVisitor<T extends AstNode> extends RecursiveAstVisitor<void> {
  final List<T> results;

  _TypedVisitor(this.results);

  @override
  void visitNode(AstNode node) {
    if (node is T) {
      results.add(node);
    }
    node.visitChildren(this);
  }
}
