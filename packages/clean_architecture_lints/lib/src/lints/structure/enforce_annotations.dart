// lib/srcs/lints/structure/enforce_annotations.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes in certain architectural layers have required annotations
/// or do not have forbidden annotations, based on the `annotations` configuration.
class EnforceAnnotations extends ArchitectureLintRule {
   static const _code = LintCode(
     name: 'enforce_annotations',
     problemMessage: 'Annotation rule violation.',
   );

  // This lint uses dynamic lint codes, so the base code is a placeholder.
  const EnforceAnnotations({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (config.annotations.rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final component = layerResolver.getComponent(
        resolver.source.fullName,
        className: node.name.lexeme,
      );
      if (component == ArchComponent.unknown) return;

      // Find the specific annotation rule for this component.
      final rule = config.annotations.ruleFor(component.id);
      if (rule == null) return;

      final declaredAnnotations = _getDeclaredAnnotations(node);

      // Check for required annotations.
      for (final requiredAnnotation in rule.required) {
        final annotationName = _normalizeAnnotationText(requiredAnnotation.name);
        if (!declaredAnnotations.contains(annotationName)) {
          reporter.atToken(
            node.name,
            LintCode(
              name: 'missing_required_annotation',
              problemMessage:
                  'This ${component.label} is missing the required `@$annotationName` annotation.',
              errorSeverity: DiagnosticSeverity.WARNING,
            ),
          );
        }
      }

      // Check for forbidden annotations.
      for (final forbiddenAnnotation in rule.forbidden) {
        final annotationName = _normalizeAnnotationText(forbiddenAnnotation.name);
        if (declaredAnnotations.contains(annotationName)) {
          reporter.atToken(
            node.name,
            LintCode(
              name: 'forbidden_annotation',
              problemMessage:
                  'This ${component.label} must not have the `@$annotationName` annotation.',
              errorSeverity: DiagnosticSeverity.WARNING,
            ),
          );
        }
      }

      // Check for suggested annotations.
      for (final suggestedAnnotation in rule.allowed) {
        final annotationName = _normalizeAnnotationText(suggestedAnnotation.name);
        if (!declaredAnnotations.contains(annotationName)) {
          reporter.atToken(
            node.name,
            LintCode(
              name: 'missing_suggested_annotation',
              problemMessage:
                  suggestedAnnotation.message ??
                  'Consider adding the `@$annotationName` annotation to this ${component.label}.',
            ),
          );
        }
      }
    });
  }

  /// Gets a set of normalized annotation names from a class declaration's metadata.
  Set<String> _getDeclaredAnnotations(ClassDeclaration node) {
    return node.metadata
        .map((annotation) => _normalizeAnnotationText(annotation.name.name))
        .toSet();
  }

  /// Normalizes annotation text by removing `@` for consistent comparison.
  String _normalizeAnnotationText(String text) {
    return text.startsWith('@') ? text.substring(1) : text;
  }
}
