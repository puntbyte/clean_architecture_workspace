// lib/srcs/lints/contract/enforce_entity_contract.dart (Main class)

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceEntityContract extends ArchitectureLintRule {
  static const _meta = EnforceEntityContractMeta();

  const EnforceEntityContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _meta);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.entity) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;
      final classElement = node.declaredFragment?.element;
      if (classElement == null) return;

      final customRule = config.inheritances.ruleFor(ArchComponent.entity.id);
      final List<InheritanceDetail> requiredSupertypes;

      if (customRule != null && customRule.required.isNotEmpty) {
        requiredSupertypes = customRule.required;
      } else {
        requiredSupertypes = [
          _meta.defaultRule,
          InheritanceDetail(
            name: _meta.defaultRule.name,
            import: 'package:${context.pubspec.name}/core/entity/entity.dart',
          ),
        ];
      }

      final hasCorrectSupertype = requiredSupertypes.any(
            (detail) => _hasSupertype(classElement, detail, context),
      );

      if (!hasCorrectSupertype) {
        final requiredNames = requiredSupertypes.map((r) => r.name).toSet().join(' or ');
        // FIX: Pass the static code object directly.
        reporter.atToken(node.name, _meta, arguments: [requiredNames, requiredNames]);
      }
    });
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail, CustomLintContext context) {
    final expectedUri = _buildExpectedUri(detail.import, context);
    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      return superElement.name == detail.name && libraryUri == expectedUri;
    });
  }

  // FIX: Simplified URI builder.
  String _buildExpectedUri(String configPath, CustomLintContext context) {
    if (configPath.startsWith('package:')) return configPath;
    final packageName = context.pubspec.name;
    return 'package:$packageName/$configPath';
  }
}

class EnforceEntityContractMeta extends LintCode {
  static const _name = 'enforce_entity_contract';
  static const _problemMessage = 'Entities must extend or implement one of: {0}.';
  static const _correctionMessage = 'Add `extends {1}` to the class definition.'; // Parameterized
  static const DiagnosticSeverity _errorSeverity = DiagnosticSeverity.WARNING;

  const EnforceEntityContractMeta()
      : super(
    name: _name,
    problemMessage: _problemMessage,
    correctionMessage: _correctionMessage,
    errorSeverity: _errorSeverity,
  );

  static String get lintName => _name;
  static String problemMessageFor(String name) => _problemMessage.replaceFirst('{0}', name);

  InheritanceDetail get defaultRule => const InheritanceDetail(
    name: 'Entity',
    import: 'package:clean_architecture_core/clean_architecture_core.dart',
  );
}
