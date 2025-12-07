// lib/src/lints/identity/logic/inheritance_logic.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

mixin InheritanceLogic {
  /// Attempts to identify the architectural component of a class based on what it
  /// extends/implements.
  String? findComponentIdByInheritance(
      ClassDeclaration node,
      ArchitectureConfig config,
      FileResolver fileResolver,
      ) {
    final element = node.declaredFragment?.element;
    if (element == null) return null;

    // FIX: Use allSupertypes to support transitive inheritance (A implements B, B extends C -> A is C)
    final supertypes = element.allSupertypes;
    if (supertypes.isEmpty) return null;

    for (final rule in config.inheritances) {
      if (rule.required.isEmpty) continue;

      final matchesRule = supertypes.any((type) {
        return rule.required.any(
              (reqDef) => matchesDefinition(type, reqDef, fileResolver, config.definitions),
        );
      });

      if (matchesRule && rule.onIds.isNotEmpty) {
        return rule.onIds.first;
      }
    }

    return null;
  }

  bool matchesDefinition(
    InterfaceType type,
    Definition def,
    FileResolver fileResolver,
    Map<String, Definition> registry,
  ) {
    final element = type.element;

    // 1. Wildcard
    if (def.isWildcard) return true;

    // 2. Reference
    if (def.ref != null) {
      final referencedDef = registry[def.ref];
      if (referencedDef != null) {
        return matchesDefinition(type, referencedDef, fileResolver, registry);
      }
    }

    // 3. Direct Type Match
    if (def.types.isNotEmpty) {
      if (def.types.contains(element.name)) {
        // Import Check
        if (def.imports.isNotEmpty) {
          final lib = element.library;
          final uri = lib.firstFragment.source.uri.toString();

          var importMatched = false;
          for (final imp in def.imports) {
            if (uri == imp || uri.startsWith(imp)) {
              importMatched = true;
              break;
            }
          }
          if (!importMatched) return false;
        }
        return true;
      }
    }

    // 4. Component Match
    if (def.component != null) {
      final lib = element.library;
      final sourcePath = lib.firstFragment.source.fullName;
      final componentContext = fileResolver.resolve(sourcePath);

      if (componentContext != null) {
        if (componentContext.matchesReference(def.component!)) {
          return true;
        }
      }
    }

    // 5. Generics (Arguments)
    // Inheritance checks usually care about the base class, not specific generics,
    // unless you want to enforce "extends State<MyWidget>".
    // If needed, you can adapt the recursive logic from TypeSafetyLogic here.

    return false;
  }

  AstNode? getNodeForType(ClassDeclaration node, InterfaceType type) {
    if (node.extendsClause?.superclass.type == type) {
      return node.extendsClause!.superclass;
    }
    if (node.implementsClause != null) {
      for (final interface in node.implementsClause!.interfaces) {
        if (interface.type == type) return interface;
      }
    }
    if (node.withClause != null) {
      for (final mixin in node.withClause!.mixinTypes) {
        if (mixin.type == type) return mixin;
      }
    }
    return null;
  }

  void report({
    required DiagnosticReporter reporter,
    required Object nodeOrToken,
    required LintCode code,
    required List<Object> arguments,
  }) {
    if (nodeOrToken is AstNode) {
      reporter.atNode(nodeOrToken, code, arguments: arguments);
    } else if (nodeOrToken is Token) {
      reporter.atToken(nodeOrToken, code, arguments: arguments);
    }
  }

  List<InterfaceType> getImmediateSupertypes(InterfaceElement element) {
    return [
      if (element.supertype != null && !element.supertype!.isDartCoreObject) element.supertype!,
      ...element.mixins,
      ...element.interfaces,
    ];
  }
}
