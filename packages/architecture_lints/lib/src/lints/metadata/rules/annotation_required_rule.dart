import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart'; // for componentMatches
import 'package:architecture_lints/src/lints/metadata/logic/annotation_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AnnotationRequiredRule extends ArchitectureLintRule with InheritanceLogic, AnnotationLogic {
  static const _code = LintCode(
    name: 'arch_annot_missing',
    problemMessage: 'Missing required annotation: "{0}".',
    correctionMessage: 'Add the annotation to the class.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const AnnotationRequiredRule() : super(code: _code);

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
      final annotations = node.metadata;

      for (final rule in rules) {
        for (final constraint in rule.required) {
          final hasMatch = annotations.any((a) => matchesConstraint(a, constraint));

          if (!hasMatch) {
            reporter.atToken(
              node.name,
              _code,
              arguments: ['@${describeConstraint(constraint)}'],
            );
          }
        }
      }
    });
  }
}