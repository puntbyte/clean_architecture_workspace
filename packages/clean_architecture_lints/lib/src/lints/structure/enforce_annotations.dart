// lib/srcs/lints/structure/enforce_annotations.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/annotations_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes have required annotations or do not have forbidden
/// annotations, based on the `annotations` configuration.
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

    context.registry.addClassDeclaration((node) {
      final component = layerResolver.getComponent(
        resolver.source.fullName,
        className: node.name.lexeme,
      );
      if (component == ArchComponent.unknown) return;

      final rule = _rules[component.id];
      if (rule == null) return;

      final declaredAnnotations = _getDeclaredAnnotations(node);

      // Check for required annotations.
      for (final requiredDetail in rule.required) {
        if (!declaredAnnotations.contains(requiredDetail.name)) {
          reporter.atToken(
            node.name,
            _requiredCode,
            arguments: [component.label, requiredDetail.name],
          );
        }
      }

      // Check for forbidden annotations.
      for (final forbiddenDetail in rule.forbidden) {
        if (declaredAnnotations.contains(forbiddenDetail.name)) {
          reporter.atToken(
            node.name,
            _forbiddenCode,
            arguments: [component.label, forbiddenDetail.name],
          );
        }
      }
    });
  }

  /// Gets a set of annotation names from a class declaration's metadata.
  Set<String> _getDeclaredAnnotations(ClassDeclaration node) {
    return node.metadata.map((annotation) => annotation.name.toSource()).toSet();
  }
}
