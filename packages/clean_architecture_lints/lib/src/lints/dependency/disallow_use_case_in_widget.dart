// lib/src/lints/dependency/disallow_use_case_in_widget.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids any reference to a UseCase within a widget file.
///
/// **Category:** Purity / Dependency
///
/// **Reasoning:** Widgets are for presentation (UI) only. They should receive
/// state from a dedicated state management class (Bloc, Cubit, Controller).
/// Business logic encapsulated in UseCases must be called from those managers,
/// never directly from a widget.
class DisallowUseCaseInWidget extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_use_case_in_widget',
    problemMessage: 'Widgets must not depend on or invoke UseCases directly.',
    correctionMessage: 'Move this dependency to a presentation manager (e.g., BLoC or Cubit).',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowUseCaseInWidget({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // 1. Scope: Only runs on files identified as Widgets
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.widget) return;

    // 2. Check: Listen for any Named Type usage.
    // This covers fields, method params, local variables, generics, and constructor calls.
    context.registry.addNamedType((node) {
      final type = node.type;
      if (type == null) return;

      final element = type.element;
      if (element == null) return;

      // [Analyzer 8.0.0 Fix] Use firstFragment.source
      final source = element.library?.firstFragment.source;
      if (source == null) return;

      // 3. Validate: Is the referenced type a UseCase?
      final targetComponent = layerResolver.getComponent(source.fullName);

      if (targetComponent == ArchComponent.usecase) {
        reporter.atNode(node, _code);
      }
    });
  }
}