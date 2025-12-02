// lib/src/lints/dependency/enforce_abstract_repository_dependency.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints_old/architecture_lint_rule.dart';
import 'package:architecture_lints/src/utils_old/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule to enforce that UseCases depend on Repository abstractions (Ports)
/// and not on concrete implementations from the data layer.
///
/// **Category:** Dependency / Dependency Inversion
///
/// **Reasoning:** UseCases live in the Domain layer (inner circle). Concrete Repositories
/// live in the Data layer (outer circle). The Dependency Rule states dependencies must
/// point inwards. Therefore, UseCases must depend on the Interface (Port) defined
/// in the Domain layer, not the Implementation in the Data layer.
class EnforceAbstractRepositoryDependency extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_abstract_repository_dependency',
    problemMessage:
        'UseCases must depend on repository abstractions (Ports), not concrete implementations.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceAbstractRepositoryDependency({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // 1. Scope: Only runs on UseCases (Domain Layer)
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.usecase) return;

    // 2. Check: Listen for any Named Type usage (fields, params, generics, locals)
    context.registry.addNamedType((node) {
      final type = node.type;
      if (type == null) return;

      final element = type.element;
      // We only care about Classes/Interfaces
      if (element is! InterfaceElement) return;

      // [Analyzer 8.0.0 Fix] Use firstFragment.source
      final source = element.library.firstFragment.source;

      // Determine what the referenced type IS
      final targetComponent = layerResolver.getComponent(
        source.fullName,
        className: element.name,
      );

      // 3. Violation: Referenced type is a Concrete Repository (Data Layer)
      // We check !isAbstract because abstract classes in the data layer might serve
      // as partial implementations, which is a slightly different architectural concern,
      // but here we strictly want to ban concrete impls.
      if (targetComponent == ArchComponent.repository &&
          element is ClassElement &&
          !element.isAbstract) {
        // 4. UX: Try to find the Port (Interface) it implements to suggest a fix
        final abstractSupertype = element.allSupertypes.firstWhereOrNull(
          (supertype) {
            final superElement = supertype.element;
            final superSource = superElement.library.firstFragment.source;

            final superComp = layerResolver.getComponent(
              superSource.fullName,
              className: superElement.name,
            );

            // Look for a supertype that is a Port (Interface in Domain)
            return superComp == ArchComponent.port;
          },
        );

        final correction = abstractSupertype != null
            ? 'Depend on the `${abstractSupertype.element.name}` interface instead.'
            : 'Depend on the abstract repository interface (Port).';

        // Report with dynamic correction message
        reporter.atNode(
          node,
          LintCode(
            name: _code.name,
            problemMessage: _code.problemMessage,
            correctionMessage: correction,
            errorSeverity: _code.errorSeverity,
          ),
        );
      }
    });
  }
}
