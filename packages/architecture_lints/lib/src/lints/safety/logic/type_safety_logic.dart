import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/config/schema/type_definition.dart';
import 'package:architecture_lints/src/config/schema/type_safety_constraint.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';

mixin TypeSafetyLogic {
  bool matchesConstraint(
      DartType type,
      TypeSafetyConstraint constraint,
      FileResolver fileResolver,
      Map<String, TypeDefinition> typeRegistry,
      ) {
    // 1. Check Canonical Element (e.g. Future)
    if (_matchesElement(type.element, constraint, typeRegistry)) {
      return true;
    }

    // 2. Check Type Alias (e.g. FutureEither)
    // Analyzer resolves typedefs to their underlying type. We must explicitly check the alias.
    if (type.alias != null) {
      if (_matchesElement(type.alias!.element, constraint, typeRegistry)) {
        return true;
      }
    }

    // 3. Component Match
    if (constraint.component != null) {
      final library = type.element?.library;
      if (library != null) {
        final sourcePath = library.firstFragment.source.fullName;
        final comp = fileResolver.resolve(sourcePath);
        if (comp != null) {
          if (comp.id == constraint.component ||
              comp.id.startsWith('${constraint.component}.') ||
              comp.id.endsWith('.${constraint.component}')) {
            return true;
          }
        }
      }
    }

    return false;
  }

  bool _matchesElement(
      Element? element, // FIX: Strictly typed as Element?
      TypeSafetyConstraint constraint,
      Map<String, TypeDefinition> typeRegistry,
      ) {
    if (element == null) return false;

    final name = element.name;
    if (name == null) return false;

    // Resolve Library URI safely
    String? libUri;
    final library = element.library;
    if (library != null) {
      libUri = library.firstFragment.source.uri.toString();
    }

    // 1. Raw Type Match
    if (constraint.types.contains(name)) {
      return true;
    }

    // 2. Definition Match
    if (constraint.definitions.isNotEmpty) {
      for (final defId in constraint.definitions) {
        final def = typeRegistry[defId];
        // Match Name
        if (def != null && def.type == name) {
          // Match Import (if defined in config)
          if (def.import != null) {
            if (libUri != null && libUri == def.import) {
              return true;
            }
          } else {
            // No import constraint in config, name match is enough
            return true;
          }
        }
      }
    }

    return false;
  }

  String describeConstraint(TypeSafetyConstraint c) {
    if (c.definitions.isNotEmpty) return c.definitions.join('/');
    if (c.types.isNotEmpty) return c.types.join('/');
    if (c.component != null) return 'Component ${c.component}';
    return '?';
  }
}