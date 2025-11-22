// lib/src/lints/contract/enforce_entity_contract.dart

import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_custom_inheritance.dart';
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Default preset for Entities.
///
/// **Behavior:**
/// - Enforces extending `Entity` from `clean_architecture_core` OR a local core file.
/// - **Disable:** If you define a rule for `entity` in `analysis_options.yaml`, this lint
///   stops running, allowing [EnforceCustomInheritance] to handle your custom rule.
class EnforceEntityContract extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_entity_contract',
    problemMessage: 'Entities must extend or implement: {0}.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
  );

  static const _defaultRule = InheritanceDetail(
    name: 'Entity',
    import: 'package:clean_architecture_core/clean_architecture_core.dart',
  );

  final bool _hasCustomRule;

  EnforceEntityContract({
    required super.config,
    required super.layerResolver,
  }) : _hasCustomRule = config.inheritances.ruleFor(ArchComponent.entity.id) != null,
       super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (_hasCustomRule) return;
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.entity) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;

      // Default Logic: Allow External Package OR Local Project Core
      final requiredSupertypes = [
        _defaultRule,
        InheritanceDetail(
          name: 'Entity',
          import: 'package:${context.pubspec.name}/core/entity/entity.dart',
        ),
      ];

      final hasCorrectSupertype = requiredSupertypes.any((detail) {
        return element.allSupertypes.any((supertype) {
          final superElement = supertype.element;
          if (superElement.name != detail.name) return false;
          final uri = superElement.library.firstFragment.source.uri.toString();
          // Check against normalized local URI or exact package URI
          return uri == detail.import || uri == _normalizeLocal(detail.import, context);
        });
      });

      if (!hasCorrectSupertype) {
        reporter.atToken(node.name, _code, arguments: ['Entity']);
      }
    });
  }

  String _normalizeLocal(String importPath, CustomLintContext context) {
    // Helper to handle the comparison for the local file definition above
    if (!importPath.startsWith('package:')) return importPath;
    return importPath;
  }
}
