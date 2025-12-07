// lib/src/lints/safety/logic/type_safety_logic.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/config/schema/type_safety_config.dart';
import 'package:architecture_lints/src/config/schema/type_safety_constraint.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';

enum MatchSpecificity { none, canonical, alias }

mixin TypeSafetyLogic {
  /// Determines how specific the match is.
  MatchSpecificity getMatchSpecificity(
    DartType type,
    List<TypeSafetyConstraint> constraintList,
    FileResolver fileResolver,
    Map<String, Definition> registry,
  ) {
    var best = MatchSpecificity.none;

    for (final c in constraintList) {
      // 1. Check Alias (Strongest Match)
      if (type.alias != null) {
        if (_matchesElement(
          type.alias!.element,
          c,
          registry,
          typeArguments: type.alias!.typeArguments,
        )) {
          return MatchSpecificity.alias; // Return immediately found highest specificity
        }
      }

      // 2. Check Canonical (Weak Match)
      if (_matchesElement(
        type.element,
        c,
        registry,
        typeArguments: _getTypeArguments(type),
      )) {
        // If we haven't found an alias match yet, mark as canonical
        if (best == MatchSpecificity.none) best = MatchSpecificity.canonical;
      }

      // 3. Component Match (Treat as Canonical for now)
      if (c.component != null) {
        final library = type.element?.library;
        if (library != null) {
          final sourcePath = library.firstFragment.source.fullName;
          final comp = fileResolver.resolve(sourcePath);
          if (comp != null && comp.matchesReference(c.component!)) {
            if (best == MatchSpecificity.none) best = MatchSpecificity.canonical;
          }
        }
      }
    }
    return best;
  }

  bool matchesAnyConstraint(
    DartType type,
    List<TypeSafetyConstraint> constraintList,
    FileResolver fileResolver,
    Map<String, Definition> registry,
  ) {
    return constraintList.any(
      (c) => matchesConstraint(type, c, fileResolver, registry),
    );
  }

  bool isExplicitlyForbidden({
    required DartType type,
    required TypeSafetyConfig configRule,
    required String kind,
    required FileResolver fileResolver,
    required Map<String, Definition> registry,
    String? paramName,
  }) {
    final forbiddenConstraints = configRule.forbidden.where((c) {
      if (c.kind != kind) return false;
      if (kind == 'parameter') {
        if (c.identifier != null && paramName != null) {
          return RegExp(c.identifier!).hasMatch(paramName);
        }
      }
      return true;
    }).toList();

    return matchesAnyConstraint(type, forbiddenConstraints, fileResolver, registry);
  }

  bool matchesConstraint(
    DartType type,
    TypeSafetyConstraint constraint,
    FileResolver fileResolver,
    Map<String, Definition> registry,
  ) {
    // 1. Check Canonical Element
    if (_matchesElement(
      type.element,
      constraint,
      registry,
      typeArguments: _getTypeArguments(type),
    )) {
      return true;
    }

    // 2. Check Type Alias
    if (type.alias != null) {
      if (_matchesElement(
        type.alias!.element,
        constraint,
        registry,
        typeArguments: type.alias!.typeArguments,
      )) {
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
          if (comp.matchesReference(constraint.component!)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  List<DartType> _getTypeArguments(DartType type) {
    if (type is InterfaceType) return type.typeArguments;
    return [];
  }

  bool _matchesElement(
    Element? element,
    TypeSafetyConstraint constraint,
    Map<String, Definition> registry, {
    List<DartType> typeArguments = const [],
  }) {
    // Handle void/dynamic special cases if needed (element is null)
    // For now assume standard types
    if (element == null) return false;
    final name = element.name;
    if (name == null) return false;

    String? libUri;
    final library = element.library;
    if (library != null) {
      libUri = library.firstFragment.source.uri.toString();
    }

    // 1. Raw Type Match
    if (constraint.types.contains(name)) return true;

    // 2. Definition Match
    if (constraint.definitions.isNotEmpty) {
      for (final defId in constraint.definitions) {
        final def = registry[defId];
        if (def == null) continue;

        if (_matchesDefinitionRecursive(def, name, libUri, typeArguments, registry)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _matchesDefinitionRecursive(
    Definition def,
    String? elementName,
    String? elementUri,
    List<DartType> typeArgs,
    Map<String, Definition> registry,
  ) {
    // A. Wildcard
    if (def.isWildcard) return true;

    // B. Reference
    if (def.ref != null) {
      final referencedDef = registry[def.ref];
      if (referencedDef == null) return false;
      return _matchesDefinitionRecursive(
        referencedDef,
        elementName,
        elementUri,
        typeArgs,
        registry,
      );
    }

    // C. Direct Match
    // Use list 'types' instead of 'type'
    if (def.types.isNotEmpty) {
      if (!def.types.contains(elementName)) return false;
    }

    // Use list 'imports' instead of 'import'
    if (def.imports.isNotEmpty) {
      if (elementUri == null) return false;
      // Must match at least one allowed import
      final importMatched = def.imports.any((imp) => elementUri.startsWith(imp));
      if (!importMatched) return false;
    }

    // D. Generics
    if (def.arguments.isNotEmpty) {
      if (typeArgs.length < def.arguments.length) return false;

      for (var i = 0; i < def.arguments.length; i++) {
        final argDef = def.arguments[i];
        final actualArgType = typeArgs[i];

        final actualArgName = actualArgType.element?.name;
        final actualArgUri = actualArgType.element?.library?.firstFragment.source.uri.toString();
        final nestedArgs = _getTypeArguments(actualArgType);

        if (!_matchesDefinitionRecursive(
          argDef,
          actualArgName,
          actualArgUri,
          nestedArgs,
          registry,
        )) {
          return false;
        }
      }
    }

    return true;
  }

  String describeConstraint(TypeSafetyConstraint c, Map<String, Definition> registry) {
    // 1. Definitions
    if (c.definitions.isNotEmpty) {
      return c.definitions
          .map((key) {
            final def = registry[key];
            return def?.describe(registry) ?? key;
          })
          .join(' or ');
    }

    // 2. Raw Types
    if (c.types.isNotEmpty) return c.types.join(' or ');

    // 3. Component
    if (c.component != null) return 'Component: ${c.component}';

    return 'Defined Rule';
  }
}
