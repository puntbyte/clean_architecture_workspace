// lib/src/lints/structure/enforce_type_safety.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/configs/type_safeties_config.dart';
import 'package:clean_architecture_lints/src/utils/ast/ast_utils.dart';
import 'package:clean_architecture_lints/src/utils/ast/semantic_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceTypeSafety extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_type_safety',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceTypeSafety({required super.config, required super.layerResolver})
    : super(code: _code);

  @override
  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (config.typeSafeties.rules.isEmpty) return;

    context.registry.addMethodDeclaration((node) {
      // Get the resolved method element - this is crucial for type resolution
      final methodElement = node.declaredFragment?.element;
      if (methodElement == null) return; // Skip if element is not resolved

      final parent = node.parent;
      final className = parent is ClassDeclaration ? parent.name.lexeme : null;
      final component = layerResolver.getComponent(resolver.source.fullName, className: className);
      if (component == ArchComponent.unknown) return;

      final rules = config.typeSafeties.rulesFor(component);
      if (rules.isEmpty) return;

      // 1. Check Return Type using the RESOLVED element type
      final returnType = methodElement.returnType;
      if (node.returnType != null) {
        _checkSafety(
          node: node.returnType!,
          type: returnType,
          // Use resolved type from element
          kind: 'return',
          identifier: null,
          rules: rules,
          reporter: reporter,
        );
      }

      // 2. Check Parameters using RESOLVED element types
      // Use element.parameters for resolved types, but node.parameters for AST nodes
      final parameters = methodElement.formalParameters;
      final parameterNodes = node.parameters?.parameters ?? <FormalParameter>[];

      for (var i = 0; i < parameters.length && i < parameterNodes.length; i++) {
        final paramElement = parameters[i];
        final paramNode = parameterNodes[i];
        final typeNode = AstUtils.getParameterTypeNode(paramNode);

        if (typeNode != null) {
          _checkSafety(
            node: typeNode,
            type: paramElement.type,
            // Use resolved type from element
            kind: 'parameter',
            identifier: paramElement.name,
            rules: rules,
            reporter: reporter,
          );
        }
      }
    });
  }

  void _checkSafety({
    required AstNode node,
    required DartType? type,
    required String kind,
    required String? identifier,
    required List<TypeSafetyRule> rules,
    required DiagnosticReporter reporter,
  }) {
    if (type == null) return;

    for (final rule in rules) {
      // A. Check Forbidden (Blacklist)
      for (final detail in rule.forbidden) {
        if (detail.kind != null && detail.kind != kind) continue;

        if (detail.identifier != null) {
          if (identifier == null) continue;
          if (!identifier.toLowerCase().contains(detail.identifier!.toLowerCase())) continue;
        }

        if (_matchesDetail(type, detail)) {
          final suggestion = _findSuggestion(rule.allowed, kind, identifier);
          final forbiddenName = _getTypeName(detail);

          final msg = suggestion != null
              ? 'Use `$suggestion` instead of `$forbiddenName`.'
              : 'Usage of `$forbiddenName` is forbidden here.';

          reporter.atNode(node, _code, arguments: [msg]);
          return;
        }
      }

      // B. Check Allowed (Whitelist)
      final allowedForContext = rule.allowed.where((d) {
        if (d.kind != null && d.kind != kind) return false;
        if (d.identifier != null) {
          if (identifier == null) return false;
          if (!identifier.toLowerCase().contains(d.identifier!.toLowerCase())) return false;
        }
        return true;
      }).toList();

      if (allowedForContext.isNotEmpty) {
        final matchedAny = allowedForContext.any((detail) => _matchesDetail(type, detail));
        if (!matchedAny) {
          final suggestion = allowedForContext.map(_getTypeName).join(' or ');
          reporter.atNode(
            node,
            _code,
            arguments: ['Expected type `$suggestion` (or allowed alternatives).'],
          );
        }
      }
    }
  }

  String? _findSuggestion(List<TypeSafetyDetail> allowed, String kind, String? identifier) {
    // Try to find a rule that matches kind and identifier to use as a suggestion
    final match = allowed.firstWhere(
      (d) =>
          (d.kind == null || d.kind == kind) &&
          (d.identifier == null || (identifier != null && identifier.contains(d.identifier!))),
      orElse: () => const TypeSafetyDetail(),
    );

    if (match.type != null || match.definition != null) {
      return _getTypeName(match);
    }
    return null;
  }

  String _getTypeName(TypeSafetyDetail detail) {
    if (detail.definition != null) {
      final typeDef = config.typeDefinitions.get(detail.definition!);
      if (typeDef != null) return typeDef.name;
      return detail.definition!;
    }
    // Return the configured type name
    return detail.type ?? detail.component ?? 'Unknown';
  }

  String? _extractPathSuffix(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;

    if (uri.scheme == 'package') {
      if (uri.pathSegments.length > 1) {
        return uri.pathSegments.sublist(1).join('/');
      }
    } else if (uri.scheme == 'file') {
      final segments = uri.pathSegments;
      final libIndex = segments.lastIndexOf('lib');
      if (libIndex != -1 && libIndex < segments.length - 1) {
        return segments.sublist(libIndex + 1).join('/');
      }
    }
    return uriString;
  }

  /// Gets the display name of a type, preferring the alias name if it's a typedef
  String _getTypeDisplayName(DartType type) {
    // For type aliases, use the alias name (e.g., FutureEither)
    if (type.alias case final alias?) {
      return alias.element.displayName; // displayName is non-nullable
    }
    // For regular types, use element name or parse from display string
    // getDisplayString() always returns a valid string
    return type.element?.name ?? type.getDisplayString().split('<').first;
  }

  /// Gets the library URI of a type, handling type aliases correctly
  String? _getTypeLibraryUri(DartType type) {
    // For type aliases, get the library from the alias element
    if (type.alias case final alias?) {
      return alias.element.library.firstFragment.source.uri.toString();
    }
    // For regular types, get the library from the type element
    return type.element?.library?.firstFragment.source.uri.toString();
  }

  // Update the _matchesDetail method:

  bool _matchesDetail(DartType type, TypeSafetyDetail detail) {
    // 1. Check Component
    if (detail.component != null) {
      final targetComp = ArchComponent.fromId(detail.component!);
      if (SemanticUtils.isComponent(type, layerResolver, targetComp)) {
        return true;
      }
    }

    // 2. Resolve Configuration Values
    String? checkName;
    String? checkImport;

    if (detail.definition != null) {
      final typeDef = config.typeDefinitions.get(detail.definition!);
      checkName = typeDef?.name;
      checkImport = typeDef?.import;
    } else {
      checkName = detail.type;
      checkImport = detail.import;
    }

    if (checkName != null) {
      // Use helper to get the correct type name (handles typedefs)
      final typeName = _getTypeDisplayName(type);

      if (typeName == checkName) {
        if (checkImport != null) {
          // Use helper to get the correct library URI
          final libraryUri = _getTypeLibraryUri(type);
          if (libraryUri == null) return false;

          // Robust Suffix Match
          final libSuffix = _extractPathSuffix(libraryUri);
          final configSuffix = _extractPathSuffix(checkImport);

          if (libSuffix != null && configSuffix != null && libSuffix == configSuffix) {
            return true;
          }
          return libraryUri == checkImport || libraryUri.endsWith(checkImport);
        }
        return true; // No import specified, name match is sufficient
      }
    }

    return false;
  }
}
