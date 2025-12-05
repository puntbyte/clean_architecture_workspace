import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/lints/metadata/logic/annotation_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AnnotationForbiddenRule extends ArchitectureLintRule with InheritanceLogic, AnnotationLogic {
  static const _codeForbidden = LintCode(
    name: 'arch_annot_forbidden',
    problemMessage: 'Forbidden annotation: "{0}".',
    correctionMessage: 'Remove this annotation.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _codeStrict = LintCode(
    name: 'arch_annot_strict',
    problemMessage: 'Annotation "{0}" is not allowed in strict mode.',
    correctionMessage: 'Only listed annotations are allowed for this component.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const AnnotationForbiddenRule() : super(code: _codeForbidden);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentConfig? component,
  }) {
    if (component == null) return;

    final rules = config.annotations.where((rule) {
      return rule.onIds.any((id) => componentMatches(id, component.id));
    }).toList();

    if (rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      for (final annotation in node.metadata) {
        for (final rule in rules) {
          // 1. Check Explicitly Forbidden
          final isForbidden = rule.forbidden.any((c) => matchesConstraint(annotation, c));
          if (isForbidden) {
            reporter.atNode(
              annotation,
              _codeForbidden,
              arguments: [annotation.name.name],
            );
            continue; // Already flagged, move to next rule/annotation
          }

          // 2. Check Strict Mode (Allow-list only)
          if (rule.mode == 'strict') {
            final isRequired = rule.required.any((c) => matchesConstraint(annotation, c));
            final isAllowed = rule.allowed.any((c) => matchesConstraint(annotation, c));

            // Note: Common built-in annotations like @override or @deprecated are usually
            // filtered out by users or ignored here. But strict mode is STRICT.
            if (!isRequired && !isAllowed) {
              reporter.atNode(
                annotation,
                _codeStrict,
                arguments: [annotation.name.name],
              );
            }
          }
        }
      }
    });
  }
}