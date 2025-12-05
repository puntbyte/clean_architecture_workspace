import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/symbol_definition.dart';
import 'package:meta/meta.dart';

/// Represents a symbol definition within the analysis context.
/// Contains the logic to match an AST Identifier against the definition.
@immutable
class SymbolContext {
  final String key; // e.g. 'locator', 'logging'
  final SymbolDefinition definition;

  const SymbolContext({required this.key, required this.definition});

  /// Checks if an [identifier] usage matches this symbol definition.
  bool matches(Identifier identifier) {
    final element = identifier.element;
    if (element == null) return false;

    // 1. Check Identifier Name (e.g., usage of variable 'sl')
    final name = identifier.name;
    if (definition.identifiers.contains(name)) {
      return _checkImport(element);
    }

    // 2. Check Static Member Access (e.g. usage of 'GetIt.instance')
    if (element is ClassElement || element is InterfaceElement) {
      if (definition.types.contains(element.name)) {
        return _checkImport(element);
      }
    }

    // 3. Check Variable Type (e.g. 'final loc = GetIt.I')
    // We check if the variable being accessed IS of the type we are tracking.
    if (element is VariableElement) {
      final typeName = element.type.element?.name;
      if (definition.types.contains(typeName)) {
        return _checkImport(element.type.element);
      }
    }

    return false;
  }

  bool _checkImport(Element? element) {
    if (definition.import == null) return true; // No import restriction
    if (element == null) return false;

    final lib = element.library;
    if (lib == null) return false;

    // Access source via fragment for analyzer 8.x compatibility
    final uri = lib.firstFragment.source.uri.toString();
    return uri == definition.import;
  }
}
