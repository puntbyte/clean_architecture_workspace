import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/definition.dart'; // Unified Schema

mixin UsageLogic {
  /// Checks if an identifier usage matches a forbidden definition.
  bool matchesDefinition(
    Identifier node,
    Definition definition,
  ) {
    final element = node.element;
    if (element == null) return false;

    // 1. Check Identifier Name (e.g. usage of variable 'sl', 'locator')
    final name = node.name;
    if (definition.identifiers.contains(name)) {
      return _checkImport(element, definition);
    }

    // 2. Check Static Access (e.g. usage of 'GetIt.instance')
    // We check if the element being accessed belongs to the Type defined.
    if (definition.type != null) {
      if (element is ClassElement || element is InterfaceElement) {
        if (element.name == definition.type) {
          return _checkImport(element, definition);
        }
      }
    }

    // 3. Check Variable Type (e.g. 'final loc = GetIt.I')
    // We check if the variable being accessed IS of the Type defined.
    if (definition.type != null) {
      if (element is VariableElement) {
        final typeName = element.type.element?.name;
        if (typeName == definition.type) {
          return _checkImport(element.type.element, definition);
        }
      }
    }

    return false;
  }

  bool _checkImport(Element? element, Definition definition) {
    if (definition.import == null) return true; // No import restriction
    if (element == null) return false;

    final lib = element.library;
    if (lib == null) return false;

    final uri = lib.firstFragment.source.uri.toString();
    return uri == definition.import;
  }
}
