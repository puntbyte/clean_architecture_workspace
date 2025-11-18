// lib/srcs/lints/contract/enforce_entity_contract.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceEntityContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_entity_contract',
    problemMessage: 'Entities must extend the base entity class `{0}`.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _defaultBaseName = 'Entity';
  static const _defaultCorePackagePath =
      'package:clean_architecture_core/clean_architecture_core.dart';

  final bool _isIgnored;

  EnforceEntityContract({required super.config, required super.layerResolver})
    : _isIgnored = config.inheritances.rules.any((r) => r.on == ArchComponent.entity.id),
      super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (_isIgnored) return;
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.entity) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      // Define the expected URI for the local project's base Entity.
      final expectedLocalUri = 'package:${context.pubspec.name}/core/entity/entity.dart';

      final hasCorrectSupertype = classElement.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        final libraryUri = superElement.library.firstFragment.source.uri.toString();

        // Check if the supertype matches the required name and comes from either
        // the official core package or the local project's core directory.
        return superElement.name == _defaultBaseName &&
            (libraryUri == _defaultCorePackagePath || libraryUri == expectedLocalUri);
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [_defaultBaseName]);
      }
    });
  }
}
