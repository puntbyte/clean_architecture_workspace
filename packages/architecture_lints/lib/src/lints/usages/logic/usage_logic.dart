import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/symbol_definition.dart';

mixin UsageLogic {
  /// Checks if an identifier expression matches a forbidden service definition.
  bool matchesService(
    Identifier node,
    SymbolDefinition service,
  ) {
    // FIX: Use .element instead of .staticElement
    final element = node.element;
    if (element == null) return false;

    // 1. Check Identifier Name (e.g., 'getIt', 'sl')
    // We check simple identifiers (sl) or prefixed ones (GetIt.I)
    final name = node.name;
    if (service.identifiers.contains(name)) {
      return _checkImport(element, service);
    }

    // 2. Check Static Type (e.g. usage of a class static member)
    // If the node is 'GetIt', check if 'GetIt' is in allowed types
    if (element is ClassElement || element is InterfaceElement) {
      if (service.types.contains(element.name)) {
        return _checkImport(element, service);
      }
    }

    // 3. Check Variable Type (e.g. 'final loc = GetIt.I')
    // If we are accessing a variable whose type is the service
    if (element is VariableElement) {
      final typeName = element.type.element?.name;
      if (service.types.contains(typeName)) {
        return _checkImport(element.type.element, service);
      }
    }

    return false;
  }

  bool _checkImport(Element? element, SymbolDefinition service) {
    if (service.import == null) return true; // No import restriction
    if (element == null) return false;

    // Check library URI
    final uri = element.library?.firstFragment.source.uri.toString();
    return uri == service.import;
  }
}
