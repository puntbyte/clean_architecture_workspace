// lib/src/domain/definition_context.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:meta/meta.dart';

@immutable
class DefinitionContext {
  final String key;
  final Definition definition;

  const DefinitionContext({required this.key, required this.definition});

  // --- Matching Logic for USAGES (AST Identifiers) ---

  bool matchesUsage(Identifier identifier) {
    final element = identifier.element;
    if (element == null) return false;

    // 1. Check Identifier Name (variable usage)
    if (definition.identifiers.contains(identifier.name)) {
      return _checkImport(element);
    }

    // 2. Check Static Access (GetIt.I)
    if (element is ClassElement || element is InterfaceElement) {
      if (definition.type == element.name) {
        return _checkImport(element);
      }
    }

    // 3. Check Variable Type (final loc = GetIt.I)
    if (element is VariableElement) {
      final typeName = element.type.element?.name;
      if (definition.type == typeName) {
        return _checkImport(element.type.element);
      }
    }

    return false;
  }

  // --- Matching Logic for TYPES (DartType) ---

  bool matchesType(DartType dartType) {
    if (_matchesElement(dartType.element)) return true;
    if (dartType.alias != null) {
      if (_matchesElement(dartType.alias!.element)) return true;
    }
    return false;
  }

  bool _matchesElement(Element? element) {
    if (element == null) return false;
    if (element.name != definition.type) return false;
    return _checkImport(element);
  }

  bool _checkImport(Element? element) {
    if (definition.imports.isEmpty) return true;
    if (element == null) return false;

    final uri = element.library?.firstFragment.source.uri.toString();
    if (uri == null) return false;

    // Check against list
    return definition.imports.contains(uri) ||
        definition.imports.any(uri.startsWith);
  }
}
