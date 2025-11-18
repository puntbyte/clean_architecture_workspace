// lib/src/lints/contract/enforce_repository_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that repository interfaces (abstract classes) extend the base Repository class.
class EnforceRepositoryContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_repository_contract',
    problemMessage: 'Repository interfaces must extend the base repository class `{0}`.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _defaultBaseName = 'Repository';
  static const _defaultCorePackagePath =
      'package:clean_architecture_core/clean_architecture_core.dart';

  final bool _isIgnored;

  EnforceRepositoryContract({required super.config, required super.layerResolver})
    : _isIgnored = config.inheritances.rules.any((r) => r.on == ArchComponent.contract.id),
      super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // If a user has a custom rule for 'contract', this specific lint is ignored.
    if (_isIgnored) return;

    // This lint only applies to files identified as repository contracts.
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.contract) return;

    context.registry.addClassDeclaration((node) {
      // Only check abstract classes, which are used as repository interfaces/contracts.
      if (node.abstractKeyword == null) return;

      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final expectedLocalUri = 'package:${context.pubspec.name}/core/repository/repository.dart';

      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        final libraryUri = superElement.library.firstFragment.source.uri.toString();

        return superElement.name == _defaultBaseName &&
            (libraryUri == _defaultCorePackagePath || libraryUri == expectedLocalUri);
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [_defaultBaseName]);
      }
    });
  }
}
