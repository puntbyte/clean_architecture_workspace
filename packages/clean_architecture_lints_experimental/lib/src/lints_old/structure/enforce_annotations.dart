// lib/src/lints/structure/enforce_annotations.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/models/configs/annotations_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes have required annotations or do not have forbidden
/// annotations.
class EnforceAnnotations extends ArchitectureRule {
  static const _code = LintCode(
    name: 'enforce_annotations',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceAnnotations({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component == ArchComponent.unknown) return;

    final rule = definition.annotations.ruleFor(component);
    if (rule == null) return;

    // 1) Flag forbidden imports (simple, based on import uri)
    context.registry.addImportDirective((node) {
      final uriString = node.uri.stringValue;
      if (uriString == null) return;

      for (final forbidden in rule.forbidden) {
        if (forbidden.import != null && _matchesImport(uriString, forbidden.import!)) {
          reporter.atNode(
            node,
            _code,
            arguments: [
              'The import `$uriString` is forbidden because it contains the `@${forbidden.name}` annotation.',
            ],
          );
          return;
        }
      }
    });

    // 2) Check declarations for forbidden/required annotations
    context.registry.addAnnotatedNode((node) {
      if (node is! ClassDeclaration && node is! MixinDeclaration && node is! EnumDeclaration) {
        return;
      }

      // A) Forbidden annotations: iterate metadata and report directly on the annotation node
      for (final annotation in node.metadata) {
        final identifier = annotation.name;
        final simpleName = identifier is PrefixedIdentifier
            ? identifier.identifier.name
            : identifier.name;
        final prefixName = identifier is PrefixedIdentifier ? identifier.prefix.name : null;

        final normalizedName = _normalizeAnnotationName(simpleName);

        final element = annotation.element ?? annotation.elementAnnotation?.element;
        final resolvedUri = _extractSourceUriFromElement(element);

        for (final forbidden in rule.forbidden) {
          final forbiddenNormalized = _normalizeAnnotationName(forbidden.name);

          if (forbiddenNormalized != normalizedName) continue;

          // If forbidden.import configured, verify it matches either resolvedUri or imports in file
          if (forbidden.import != null) {
            var matched = false;

            if (resolvedUri != null && _matchesImport(resolvedUri, forbidden.import!)) {
              matched = true;
            } else {
              // Fallback to scanning imports in the compilation unit (and match prefix if present)
              final compilationUnit = annotation.thisOrAncestorOfType<CompilationUnit>();
              if (compilationUnit != null) {
                final found = compilationUnit.directives.whereType<ImportDirective>().any((imp) {
                  final uriString = imp.uri.stringValue;
                  if (uriString == null) return false;
                  if (!_matchesImport(uriString, forbidden.import!)) return false;
                  if (prefixName != null) return imp.prefix?.name == prefixName;

                  return true;
                });
                matched = found;
              }
            }

            if (!matched) continue;
          }

          // Report forbidden annotation
          reporter.atNode(
            annotation,
            _code,
            arguments: [
              'This ${component.label} must not have the `@${forbidden.name}` annotation.',
            ],
          );
        }
      } // end metadata loop

      // B) Required annotations: check the container (class/mixin/enum) for requireds
      final nameToken = _getNameToken(node);
      if (nameToken == null) return;

      final declared = _getDeclaredAnnotations(node);
      for (final required in rule.required) {
        if (!_annotationSatisfiesRequired(declared, required, node)) {
          reporter.atToken(
            nameToken,
            _code,
            arguments: [
              'This ${component.label} is missing the required `@${required.name}` annotation.',
            ],
          );
        }
      }
    });
  }

  // --- Helpers -------------------------------------------------------------

  Token? _getNameToken(AnnotatedNode node) {
    if (node is ClassDeclaration) return node.name;
    if (node is MixinDeclaration) return node.name;
    if (node is EnumDeclaration) return node.name;
    return null;
  }

  /// Checks whether any declared annotation satisfies the `required` detail.
  /// This verifies name (normalized) and — if an import is provided — it verifies via:
  ///  1) resolved sourceUri (if available)
  ///  2) imports in the compilation unit (fallback)
  bool _annotationSatisfiesRequired(
    List<_ResolvedAnnotation> declared,
    AnnotationDetail required,
    AnnotatedNode node,
  ) {
    final requiredNameNorm = _normalizeAnnotationName(required.name);

    for (final d in declared) {
      if (_normalizeAnnotationName(d.name) != requiredNameNorm) continue;

      // If no import restriction, name match is sufficient
      if (required.import == null) return true;

      // If the declared annotation resolved to a sourceUri, match it
      if (d.sourceUri != null && _matchesImport(d.sourceUri!, required.import!)) {
        return true;
      }

      // Fallback: scan imports of the compilation unit and match by uri (and prefix unknown here)
      final compilationUnit = node.thisOrAncestorOfType<CompilationUnit>();
      if (compilationUnit != null) {
        final found = compilationUnit.directives.whereType<ImportDirective>().any((imp) {
          final uriString = imp.uri.stringValue;
          if (uriString == null) return false;
          return _matchesImport(uriString, required.import!);
        });
        if (found) return true;
      }

      // Not matched by import -> continue searching other declared annotations
    }

    return false;
  }

  bool _matchesImport(String actual, String expected) {
    if (actual == expected) return true;
    if (actual.startsWith(expected)) return true;
    if (expected.startsWith('package:') && actual.endsWith(expected.split('/').last)) return true;
    return false;
  }

  /// Extract a source/library URI for an element using the documented API paths
  /// (no casts/dynamic). Probe the common places used by analyzer 8.x.
  String? _extractSourceUriFromElement(Element? element) {
    if (element == null) return null;

    // 1) element.library?.firstFragment?.source?.uri
    final lib = element.library;
    if (lib != null) {
      final libFirst = lib.firstFragment;
      final libSource = libFirst.source;
      final libUri = libSource.uri;
      return libUri.toString();
    }

    // 2) element.firstFragment.libraryFragment?.source?.uri
    final firstFrag = element.firstFragment;
    final libFrag = firstFrag.libraryFragment;
    if (libFrag != null) {
      final source = libFrag.source;
      final uri = source.uri;
      return uri.toString();
    }

    // 3) enclosingElement?.library?.firstFragment?.source?.uri
    final enclosing = element.enclosingElement;
    final enclosingLib = enclosing?.library;
    if (enclosingLib != null) {
      final encFirst = enclosingLib.firstFragment;
      final encSource = encFirst.source;
      final encUri = encSource.uri;
      return encUri.toString();
    }

    return null;
  }

  List<_ResolvedAnnotation> _getDeclaredAnnotations(AnnotatedNode node) {
    return node.metadata.map((annotation) {
      final identifier = annotation.name;
      final name = identifier is PrefixedIdentifier ? identifier.identifier.name : identifier.name;
      final element = annotation.element ?? annotation.elementAnnotation?.element;
      final sourceUri = _extractSourceUriFromElement(element);
      return _ResolvedAnnotation(name, sourceUri);
    }).toList();
  }

  String _normalizeAnnotationName(String name) {
    var n = name;
    if (n.startsWith('@')) n = n.substring(1);
    return n.toLowerCase();
  }
}

class _ResolvedAnnotation {
  final String name;
  final String? sourceUri;

  _ResolvedAnnotation(this.name, this.sourceUri);
}
