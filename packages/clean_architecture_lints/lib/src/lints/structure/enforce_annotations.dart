// lib/src/lints/structure/enforce_annotations.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/configs/annotations_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes have required annotations or do not have forbidden
/// annotations.
class EnforceAnnotations extends ArchitectureLintRule {
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

    final rule = config.annotations.ruleFor(component.id);
    if (rule == null) return;

    // 1. Check Imports (Flag forbidden packages)
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
          return; // Report once per import
        }
      }
    });

    // 2. Check Declarations (Classes, Mixins, Enums)
    context.registry.addAnnotatedNode((node) {
      // We only care about container declarations that can hold architectural logic.
      if (node is! ClassDeclaration && node is! MixinDeclaration && node is! EnumDeclaration) {
        return;
      }

      // A. Check Forbidden Annotations (Iterate metadata on the node)
      for (final annotation in node.metadata) {
        final identifier = annotation.name;
        final simpleName = identifier is PrefixedIdentifier
            ? identifier.identifier.name
            : identifier.name;
        final prefixName = identifier is PrefixedIdentifier ? identifier.prefix.name : null;

        final normalizedAnnotationName = _normalizeAnnotationName(simpleName);

        // Resolve element to try to get library/source URI
        final element = annotation.element ?? annotation.elementAnnotation?.element;
        final sourceUri = _extractSourceUriFromElement(element);

        for (final forbidden in rule.forbidden) {
          final forbiddenNameNormalized = _normalizeAnnotationName(forbidden.name);

          // 1. Name Check (Case-insensitive)
          if (forbiddenNameNormalized != normalizedAnnotationName) continue;

          // 2. Import Check (if configured)
          if (forbidden.import != null) {
            var matched = false;

            // Path A: Resolved Element URI (Most accurate)
            if (sourceUri != null && _matchesImport(sourceUri, forbidden.import!)) {
              matched = true;
            }
            // Path B: Fallback to scanning imports (If resolution failed or element is null)
            else {
              final compilationUnit = annotation.thisOrAncestorOfType<CompilationUnit>();
              if (compilationUnit != null) {
                final found = compilationUnit.directives.whereType<ImportDirective>().any((imp) {
                  final uriString = imp.uri.stringValue;
                  if (uriString == null) return false;
                  if (!_matchesImport(uriString, forbidden.import!)) return false;

                  if (prefixName != null) {
                    return imp.prefix?.name == prefixName;
                  }
                  return true;
                });
                matched = found;
              }
            }

            if (!matched) continue;
          }

          // Report ON THE ANNOTATION node
          reporter.atNode(
            annotation,
            _code,
            arguments: [
              'This ${component.label} must not have the `@${forbidden.name}` annotation.',
            ],
          );
        }
      }

      // B. Check Missing (Required) Annotations on the container
      final nodeName = _getNameToken(node);
      if (nodeName != null) {
        final declaredAnnotations = _getDeclaredAnnotations(node);
        for (final required in rule.required) {
          if (!_hasAnnotation(declaredAnnotations, required)) {
            reporter.atToken(
              nodeName,
              _code,
              arguments: [
                'This ${component.label} is missing the required `@${required.name}` annotation.',
              ],
            );
          }
        }
      }
    });
  }

  Token? _getNameToken(AnnotatedNode node) {
    if (node is ClassDeclaration) return node.name;
    if (node is MixinDeclaration) return node.name;
    if (node is EnumDeclaration) return node.name;
    return null;
  }

  bool _hasAnnotation(List<_ResolvedAnnotation> declared, AnnotationDetail target) {
    return declared.any((declaredAnnotation) {
      if (_normalizeAnnotationName(declaredAnnotation.name) !=
          _normalizeAnnotationName(target.name)) {
        return false;
      }
      if (target.import != null && declaredAnnotation.sourceUri != null) {
        return _matchesImport(declaredAnnotation.sourceUri!, target.import!);
      }
      return true;
    });
  }

  bool _matchesImport(String actual, String expected) {
    if (actual == expected) return true;
    if (actual.startsWith(expected)) return true;
    if (expected.startsWith('package:') && actual.endsWith(expected.split('/').last)) return true;
    return false;
  }

  String? _extractSourceUriFromElement(Element? element) {
    if (element == null) return null;

    // 1. Direct Library Access
    final lib = element.library;
    if (lib != null) {
      // [Analyzer 8.0.0] Use firstFragment.source.uri
      return lib.firstFragment.source.uri.toString();
    }

    // 2. Fragment Access (if Library is null on element directly)
    // Note: In Analyzer 8.0.0, element.firstFragment might be available even if element.library is not fully wired?
    // Safest path is usually element.library.

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
