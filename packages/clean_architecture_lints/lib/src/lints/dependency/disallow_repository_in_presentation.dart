// lib/src/lints/dependency/disallow_repository_in_presentation.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids any reference to a Repository (Port) within the presentation layer.
///
/// **Category:** Purity / Dependency
///
/// **Reasoning:** The presentation layer (Widgets, Blocs, etc.) should not be
/// coupled to the Repository contract. Its dependency should be on specific
/// `UseCases`. A UseCase provides a narrow, functional contract, whereas a
/// Repository is a broad data contract. Depending on a repository tempts the
/// presentation layer to perform business logic that belongs in a UseCase.
class DisallowRepositoryInPresentation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_repository_in_presentation',
    problemMessage: 'Presentation layer purity violation: Do not depend directly on a Repository.',
    correctionMessage: 'Depend on a specific UseCase instead, and inject it via the constructor.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowRepositoryInPresentation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // 1. Scope: This rule applies ONLY to files within the presentation layer.
    final currentComponent = layerResolver.getComponent(resolver.source.fullName);
    if (currentComponent.layer != ArchComponent.presentation) return;

    // 2. Check: Listen for ANY named type usage (fields, params, generics, variables).
    context.registry.addNamedType((node) {
      final type = node.type;
      if (type == null) return;

      final element = type.element;
      if (element == null) return;

      // [Analyzer 8.0.0 Fix] Use firstFragment.source
      final source = element.library?.firstFragment.source;
      if (source == null) return;

      // 3. Validate: Is the referenced type a Repository Interface (Port)?
      final targetComponent = layerResolver.getComponent(source.fullName);

      if (targetComponent == ArchComponent.port) {
        reporter.atNode(node, _code);
      }
    });
  }
}