// lib/src/lints/usages/logic/usage_logic.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';

mixin UsageLogic {
  bool matchesDefinition(Identifier node, Definition definition) {
    final element = node.element;
    if (element == null) return false;

    // 1. Check Identifiers (Variable Names)
    if (definition.identifiers.contains(node.name)) {
      return _checkImport(element, definition);
    }

    // 2. Check Static Access (Class Names)
    if (element is ClassElement || element is InterfaceElement) {
      final name = element.name;
      // Check singular 'type' AND list 'types'
      if (definition.type == name || definition.types.contains(name)) {
        return _checkImport(element, definition);
      }
    }

    // 3. Check Variable Type
    if (element is VariableElement) {
      final typeName = element.type.element?.name;
      if (typeName != null) {
        if (definition.type == typeName || definition.types.contains(typeName)) {
          return _checkImport(element.type.element, definition);
        }
      }
    }

    return false;
  }

  bool _checkImport(Element? element, Definition definition) {
    // If no imports defined, match ANY import
    if (definition.imports.isEmpty) return true;

    if (element == null) return false;

    final lib = element.library;
    if (lib == null) return false;

    final uri = lib.firstFragment.source.uri.toString();

    // Check if URI matches any allowed import
    for (final imp in definition.imports) {
      if (_matchesUri(uri, imp)) return true;
    }

    return false;
  }

  bool _matchesUri(String actual, String expected) {
    if (actual == expected) return true;
    if (actual.startsWith('package:') && expected.startsWith('package:')) {
      return actual.startsWith(expected);
    }
    return false;
  }
}
