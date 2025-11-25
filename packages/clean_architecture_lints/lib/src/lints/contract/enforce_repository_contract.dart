// lib/src/lints/contract/enforce_repository_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that Repository implementations (Data Layer) implement a
/// Port Interface (Domain Layer).
class EnforceRepositoryContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_repository_contract',
    // FIX: Updated message to match the test expectation ("Port interface")
    problemMessage:
        'Repository implementations must implement a Port interface from the domain layer.',
    correctionMessage: 'Add `implements YourPortInterface` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceRepositoryContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.repository) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;

      final hasPortSupertype = element.allSupertypes.any((supertype) {
        final source = supertype.element.library.firstFragment.source;
        return layerResolver.getComponent(source.fullName) == ArchComponent.port;
      });

      if (!hasPortSupertype) reporter.atToken(node.name, _code);
    });
  }
}
