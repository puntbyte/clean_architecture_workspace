// lib/src/lints/contract/enforce_port_contract.dart

import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that Port interfaces (abstract classes in the Domain layer)
/// extend the base Repository class.
class EnforcePortContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_port_contract',
    problemMessage: 'Port interfaces must extend the base repository class `{0}`.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
  );

  static const _defaultBaseName = 'Repository';
  static const _externalPackageUri = 'package:clean_architecture_core/clean_architecture_core.dart';

  final bool _hasCustomRule;

  EnforcePortContract({
    required super.config,
    required super.layerResolver,
  }) : _hasCustomRule = config.inheritances.ruleFor(ArchComponent.port.id) != null,
       super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (_hasCustomRule) return;

    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.port) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword == null) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;

      final localCoreUri = 'package:${context.pubspec.name}/core/repository/port.dart';

      final hasCorrectSupertype = element.allSupertypes.any((supertype) {
        final superElement = supertype.element;
        if (superElement.name != _defaultBaseName) return false;

        final uri = superElement.library.firstFragment.source.uri.toString();
        return uri == _externalPackageUri || uri == localCoreUri;
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: [_defaultBaseName]);
      }
    });
  }
}
