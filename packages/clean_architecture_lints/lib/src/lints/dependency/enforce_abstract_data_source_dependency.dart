// lib/src/lints/dependency/enforce_abstract_data_source_dependency.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule to enforce that Repository Implementations depend on DataSource
/// abstractions (interfaces) and not on concrete implementations.
///
/// **Category:** Dependency / Dependency Inversion
class EnforceAbstractDataSourceDependency extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_abstract_data_source_dependency',
    problemMessage:
        'Repositories must depend on DataSource abstractions, not concrete implementations.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceAbstractDataSourceDependency({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // 1. Scope: Only runs on Repository Implementations
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    // 2. Check: Listen for any Named Type usage (fields, params, generics, locals)
    context.registry.addNamedType((node) {
      final type = node.type;
      if (type == null) return;

      final element = type.element;
      // We only care about Classes/Interfaces (not typedefs, enums, etc. usually)
      if (element is! InterfaceElement) return;

      // [Analyzer 8.0.0 Fix] Use firstFragment.source
      final source = element.library.firstFragment.source;

      // Determine what the referenced type IS
      final targetComponent = layerResolver.getComponent(
        source.fullName,
        className: element.name,
      );

      // 3. Violation: Referenced type is a Concrete Source Implementation
      // We also check `!isAbstract` to ensure we don't flag abstract base classes
      // that might be in the implementation folder (though unlikely).
      if (targetComponent == ArchComponent.sourceImplementation &&
          element is ClassElement &&
          !element.isAbstract) {
        // 4. UX: Try to find the interface it implements to suggest a fix
        final abstractSupertype = element.allSupertypes.firstWhereOrNull(
          (supertype) {
            final superElement = supertype.element;
            final superSource = superElement.library.firstFragment.source;

            final superComp = layerResolver.getComponent(
              superSource.fullName,
              className: superElement.name,
            );

            return (superElement is ClassElement && superElement.isAbstract) &&
                superComp == ArchComponent.sourceInterface;
          },
        );

        final correction = abstractSupertype != null
            ? 'Depend on the `${abstractSupertype.element.name}` interface instead.'
            : 'Depend on the abstract DataSource interface.';

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
