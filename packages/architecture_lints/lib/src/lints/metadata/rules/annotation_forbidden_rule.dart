import 'package:analyzer/dart/ast/ast.dart';

// Hide LintCode from analyzer to avoid conflict with custom_lint_builder
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/annotation_config.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/metadata/base/annotation_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AnnotationForbiddenRule extends AnnotationBaseRule {
  static const _code = LintCode(
    name: 'arch_annot_forbidden',
    problemMessage: '{0}',
    correctionMessage: 'Remove the forbidden element.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const AnnotationForbiddenRule() : super(code: _code);

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
        for (final forbidden in rule.forbidden) {
          if (matchesConstraint(annotation, forbidden)) {
            final msg =
                'Forbidden annotation "@${annotation.name.name}" on ${component.displayName}.';

            reporter.atNode(
              annotation,
              _code,
              arguments: [msg],
            );
            break;
          }
        }
      }
    }
  }

  @override
  void checkImports({
    required ImportDirective node,
    required List<AnnotationConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  }) {
    for (final rule in rules) {
      for (final forbidden in rule.forbidden) {
        if (forbidden.import == null) continue;

        if (matchesImportConstraint(node, forbidden)) {
          final importUri = node.uri.stringValue ?? '';
          final annotName = forbidden.types.join('/');
          final msg = 'Forbidden import "$importUri" because it provides "@$annotName".';

          // FIX: Highlight only the URI part, not the whole import line
          reporter.atNode(
            node.uri,
            _code,
            arguments: [msg],
          );
          return;
        }
      }
    }
  }
}
