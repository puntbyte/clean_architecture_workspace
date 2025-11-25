// lib/src/lints/structure/enforce_annotations.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/annotations_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes have required annotations or do not have forbidden annotations.
class EnforceAnnotations extends ArchitectureLintRule {
  static const _requiredCode = LintCode(
    name: 'enforce_annotations_required',
    problemMessage: 'This {0} is missing the required `@{1}` annotation.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _forbiddenCode = LintCode(
    name: 'enforce_annotations_forbidden',
    problemMessage: 'This {0} must not have the `@{1}` annotation.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _forbiddenImportCode = LintCode(
    name: 'enforce_annotations_forbidden_import',
    problemMessage: 'The import `{0}` is forbidden because it contains the `@{1}` annotation.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final Map<String, AnnotationRule> _rules;

  EnforceAnnotations({required super.config, required super.layerResolver})
    : _rules = {
        for (final rule in config.annotations.rules)
          for (final componentId in rule.on) componentId: rule,
      },
      super(code: _requiredCode);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (_rules.isEmpty) return;

    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component == ArchComponent.unknown) return;

    final rule = _rules[component.id];
    if (rule == null) return;

    // 1. Check Imports (Flag forbidden packages)
    context.registry.addImportDirective((node) {
      final uriString = node.uri.stringValue;
      if (uriString == null) return;

      for (final forbidden in rule.forbidden) {
        if (forbidden.import != null && _matchesImport(uriString, forbidden.import!)) {
          reporter.atNode(
            node,
            _forbiddenImportCode,
            arguments: [uriString, forbidden.name],
          );
        }
      }
    });

    // 2. Check Class Declaration (Flag usage & missing)
    context.registry.addClassDeclaration((node) {
      final declaredAnnotations = _getDeclaredAnnotations(node);

      // Check Forbidden
      for (final forbidden in rule.forbidden) {
        if (_hasAnnotation(declaredAnnotations, forbidden)) {
          reporter.atToken(
            node.name,
            _forbiddenCode,
            arguments: [component.label, forbidden.name],
          );
        }
      }

      // Check Required
      for (final required in rule.required) {
        if (!_hasAnnotation(declaredAnnotations, required)) {
          reporter.atToken(
            node.name,
            _requiredCode,
            arguments: [component.label, required.name],
          );
        }
      }
    });
  }

  /// Checks if the list of annotations on the class contains the target annotation.
  bool _hasAnnotation(List<_ResolvedAnnotation> declared, AnnotationDetail target) {
    return declared.any((declaredAnnotation) {
      // 1. Name Check
      if (declaredAnnotation.name != target.name) return false;

      // 2. Import/Source Check (if configured)
      if (target.import != null && declaredAnnotation.sourceUri != null) {
        return _matchesImport(declaredAnnotation.sourceUri!, target.import!);
      }

      // If config has no import, we match by name only (lax check)
      return true;
    });
  }

  bool _matchesImport(String actual, String expected) {
    if (actual == expected) return true;
    if (actual.startsWith(expected)) return true;
    if (expected.startsWith('package:') && actual.endsWith(expected.split('/').last)) return true;
    return false;
  }

  /// Extracts annotation metadata from the AST node.
  List<_ResolvedAnnotation> _getDeclaredAnnotations(ClassDeclaration node) {
    return node.metadata.map((annotation) {
      final name = annotation.name.name;

      // Resolve the element to get the source URI
      final element = annotation.element ?? annotation.elementAnnotation?.element;

      // [Analyzer 8.0.0 Fix] Use firstFragment.source.uri
      final sourceUri = element?.library?.firstFragment.source.uri.toString();

      return _ResolvedAnnotation(name, sourceUri);
    }).toList();
  }
}

class _ResolvedAnnotation {
  final String name;
  final String? sourceUri;

  _ResolvedAnnotation(this.name, this.sourceUri);
}
