// lib/src/lints/usages/logic/usage_logic.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';

mixin UsageLogic {
  bool matchesDefinition(Identifier node, Definition definition) {
    final element = node.element;
    if (element == null) return false;

    final name = node.name;

    // 1. Identifiers
    if (definition.identifiers.contains(name)) {
      return _checkImport(element, definition);
    }

    // 2. Static Access
    if (definition.types.isNotEmpty) {
      if (element is ClassElement || element is InterfaceElement) {
        if (definition.types.contains(element.name)) {
          return _checkImport(element, definition);
        }
      }
    }

    // 3. Variable Type
    if (definition.types.isNotEmpty) {
      if (element is VariableElement) {
        final typeName = element.type.element?.name;
        if (definition.types.contains(typeName)) {
          return _checkImport(element.type.element, definition);
        }
      }
    }

    return false;
  }

  bool _checkImport(Element? element, Definition definition) {
    if (definition.imports.isEmpty) return true;
    if (element == null) return false;

    final lib = element.library;
    if (lib == null) return false;

    final elementUri = lib.firstFragment.source.uri.toString();

    for (final expected in definition.imports) {
      if (elementUri == expected) return true;
      if (elementUri.startsWith(expected)) return true;
    }

    return false;
  }
}
