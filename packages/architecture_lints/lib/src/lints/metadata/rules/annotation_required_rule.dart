// lib/src/lints/metadata/annotation_required_rule.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/annotation_config.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/metadata/base/annotation_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AnnotationRequiredRule extends AnnotationBaseRule {
  static const _code = LintCode(
    name: 'arch_annot_missing',
    problemMessage: 'Missing required annotation: "{0}".',
    correctionMessage: 'Add the annotation to the class.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const AnnotationRequiredRule() : super(code: _code);

  @override
  void checkAnnotations({
    required ClassDeclaration node,
    required List<AnnotationConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  }) {
    final declaredAnnotations = node.metadata;

    for (final rule in rules) {
      for (final constraint in rule.required) {
        // Check if ANY declared annotation satisfies this requirement
        final isSatisfied = declaredAnnotations.any(
          (annotation) => matchesConstraint(annotation, constraint),
        );

        if (!isSatisfied) {
          reporter.atToken(
            node.name,
            _code,
            arguments: ['@${describeConstraint(constraint)}'],
          );
        }
      }
    }
  }
}
