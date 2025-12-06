// lib/src/lints/identity/logic/inheritance_logic.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart'; // Use Definition
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

mixin InheritanceLogic {
  String? findComponentIdByInheritance(
    ClassDeclaration node,
    ArchitectureConfig config,
    FileResolver fileResolver,
  ) {
    final element = node.declaredFragment?.element;
    if (element == null) return null;

    final supertypes = getImmediateSupertypes(element);
    if (supertypes.isEmpty) return null;

    for (final rule in config.inheritances) {
      if (rule.required.isEmpty) continue;

      final matchesRule = supertypes.any(
        (type) => matchesDefinition(
          type,
          rule.required,
          fileResolver,
          config.definitions,
        ),
      );

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

    // 1. Direct Type Match
    if (def.type != null) {
      if (element.name == def.type) {
        if (def.import != null) {
          final uri = element.library.firstFragment.source.uri.toString();
          if (uri != def.import) return false;
        }
        return true;
      }
    }

    // 2. Component Match
    if (def.component != null) {
      final sourcePath = element.library.firstFragment.source.fullName;
      final componentContext = fileResolver.resolve(sourcePath);

      if (componentContext != null) {
        if (componentContext.matchesReference(def.component!)) {
          return true;
        }
      }
    }

    // 3. Reference (e.g. 'failure.base')
    if (def.ref != null) {
      final referencedDef = registry[def.ref];
      if (referencedDef != null) {
        return matchesDefinition(type, referencedDef, fileResolver, registry);
      }
    }

    // 4. Wildcard
    if (def.isWildcard) return true;

    // 5. Arguments (Recursion) - Handled for TypeSafety,
    // but typically Inheritance rules don't check strict generics unless specified.
    // If you need deep generic check here, you can adapt TypeSafetyLogic's recursive matcher.

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

  String describeDefinition(Definition def, [Map<String, Definition>? registry]) {
    if (def.type != null) return def.type!;
    if (def.component != null) return 'Component: ${def.component}';
    if (def.ref != null) {
      if (registry != null) {
        final resolved = registry[def.ref];
        if (resolved != null) return describeDefinition(resolved, registry);
      }
      return 'Defined: ${def.ref}';
    }
    return 'Defined Rule';
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
