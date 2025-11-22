// lib/src/lints/purity/disallow_model_in_domain.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids any reference to a data-layer `Model` within the domain layer.
///
/// **Category:** Purity
///
/// **Reasoning:** The domain layer must not know about the implementation details of the
/// data layer. Data-layer Models (DTOs) are a data transfer detail. The domain layer
/// should only ever deal with its own pure `Entity` objects.
class DisallowModelInDomain extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_model_in_domain',
    problemMessage: 'Domain layer purity violation: Do not use a data-layer Model.',
    correctionMessage: 'Replace this Model with a pure domain Entity.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowModelInDomain({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);

    // This rule applies to ANY file within the domain layer.
    if (component.layer != ArchComponent.domain) return;

    // Visit every TypeAnnotation in the file.
    context.registry.addTypeAnnotation((node) {
      final type = node.type;
      if (type == null) return;

      // Get the source file where this type is defined.
      // We use the element directly to avoid recursion issues.
      final source = type.element?.library?.firstFragment.source;
      if (source == null) return;

      // Check if the referenced type is defined in a Model component.
      if (layerResolver.getComponent(source.fullName) == ArchComponent.model) {
        reporter.atNode(node, _code);
      }
    });
  }
}
