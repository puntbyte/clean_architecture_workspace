// lib/src/lints/metadata/rules/annotation_strict_rule.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/enums/annotation_mode.dart';
import 'package:architecture_lints/src/config/schema/annotation_config.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/metadata/base/annotation_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AnnotationStrictRule extends AnnotationBaseRule {
  static const _code = LintCode(
    name: 'arch_annot_strict',
    problemMessage: 'Annotation "{0}" is not allowed in strict mode.',
    correctionMessage: 'Only listed annotations are allowed for this component.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const AnnotationStrictRule() : super(code: _code);

  @override
  void checkAnnotations({
    required ClassDeclaration node,
    required List<AnnotationConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  }) {
    for (final annotation in node.metadata) {
      for (final rule in rules) {
        // Only run if strict mode is enabled
        if (rule.mode != AnnotationMode.strict) continue;

        // Check if allowed (Whitelist)
        // If it matches ANY required or allowed constraint, it is valid.
        final isRequired = rule.required.any((c) => matchesConstraint(annotation, c));
        final isAllowed = rule.allowed.any((c) => matchesConstraint(annotation, c));

        if (!isRequired && !isAllowed) {
          reporter.atNode(
            annotation,
            _code,
            arguments: [annotation.name.name],
          );
        }
      }
    }
  }
}
