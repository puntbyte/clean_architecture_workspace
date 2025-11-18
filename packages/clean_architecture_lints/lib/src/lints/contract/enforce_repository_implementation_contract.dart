// lib/src/lints/contract/enforce_repository_implementation_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces that Repository Implementations implement a corresponding
/// Repository Interface (contract) from the domain layer.
///
/// **Reasoning:** This is the cornerstone of the Dependency Inversion Principle
/// between the Data and Domain layers. It ensures that the concrete
/// implementation in the data layer strictly adheres to the abstract contract
/// defined in the domain layer, allowing the domain layer to remain completely
/// independent of data layer details.
class EnforceRepositoryImplementationContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_repository_implementation_contract',
    problemMessage:
        'Repository implementations must implement a repository interface from the domain layer.',
    correctionMessage: 'Add `implements YourRepositoryInterface` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceRepositoryImplementationContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This rule only applies to files identified as repository implementations.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.repository) return;

    context.registry.addClassDeclaration((node) {
      // The rule only applies to concrete classes, not abstract base implementations.
      if (node.abstractKeyword != null) return;

      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      // The core logic: check if ANY supertype (direct or transitive)
      // comes from a file that the LayerResolver identifies as a `contract`.
      final hasContractSupertype = classElement.allSupertypes.any((supertype) {
        // We get the source file of the supertype's element.
        final source = supertype.element.library.firstFragment.source;

        // We then ask the LayerResolver what kind of component it is.
        return layerResolver.getComponent(source.fullName) == ArchComponent.contract;
      });

      if (!hasContractSupertype) {
        reporter.atToken(node.name, _code);
      }
    });
  }
}
