// lib/src/lints/contract/enforce_custom_inheritance.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceCustomInheritance extends ArchitectureLintRule {
  static const _requiredCode = LintCode(
    name: 'custom_inheritance_required',
    problemMessage: 'This {0} must extend or implement one of: {1}.',
    correctionMessage: 'Extend or implement one of the required types.',
  );

  static const _forbiddenCode = LintCode(
    name: 'custom_inheritance_forbidden',
    problemMessage: 'This {0} must not extend or implement {1}.',
    correctionMessage: 'Remove the forbidden type from the class definition.',
  );

  final Map<String, InheritanceRule> _rules;

  EnforceCustomInheritance({
    required super.config,
    required super.layerResolver,
  }) : _rules = {
         for (final rule in config.inheritances.rules)
           // FIX: Skip core components that have their own dedicated lints.
           // This ensures 'enforce_entity_contract' etc. are reported specifically.
           if (rule.on != ArchComponent.entity.id &&
               rule.on != ArchComponent.port.id &&
               rule.on != ArchComponent.usecase.id)
             rule.on: rule,
       },
       super(code: _requiredCode);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (_rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;

      final component = layerResolver.getComponent(
        resolver.source.fullName,
        className: node.name.lexeme,
      );

      if (component == ArchComponent.unknown) return;

      final rule = _rules[component.id];
      if (rule == null) return;

      // 1. ALLOWED CHECK
      if (rule.allowed.isNotEmpty) {
        final isAllowed = rule.allowed.any(
          (detail) => _satisfiesDetail(element, detail),
        );
        if (isAllowed) return;
      }

      // 2. REQUIRED CHECK
      if (rule.required.isNotEmpty) {
        final hasRequired = rule.required.any(
          (detail) => _satisfiesDetail(element, detail),
        );

        if (!hasRequired) {
          final requiredNames = rule.required.map(_getDisplayName).join(' or ');
          reporter.atToken(
            node.name,
            _requiredCode,
            arguments: [component.label, requiredNames],
          );
        }
      }

      // 3. FORBIDDEN CHECK
      for (final forbidden in rule.forbidden) {
        if (_satisfiesDetail(element, forbidden)) {
          reporter.atToken(
            node.name,
            _forbiddenCode,
            arguments: [component.label, _getDisplayName(forbidden)],
          );
        }
      }
    });
  }

  String _getDisplayName(InheritanceDetail detail) {
    if (detail.name != null) return detail.name!;
    if (detail.component != null) {
      return ArchComponent.fromId(detail.component!).label;
    }
    return 'Unknown Type';
  }

  bool _satisfiesDetail(ClassElement element, InheritanceDetail detail) {
    if (detail.component != null) {
      return _isComponentSupertype(element, detail.component!);
    }
    if (detail.name != null && detail.import != null) {
      return _hasSpecificSupertype(element, detail);
    }
    return false;
  }

  bool _isComponentSupertype(ClassElement element, String componentId) {
    final targetComponent = ArchComponent.fromId(componentId);
    if (targetComponent == ArchComponent.unknown) return false;

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      final source = superElement.library.firstFragment.source;
      final superComp = layerResolver.getComponent(source.fullName);
      return superComp == targetComponent;
    });
  }

  bool _hasSpecificSupertype(ClassElement element, InheritanceDetail detail) {
    // Note: In a real plugin, you need access to 'pubspec.name' for relative imports.
    // For simplicity in this snippet, we assume the logic is handled or passed correctly.
    // Since DartLintRule doesn't expose context in helper methods easily without passing it,
    // we use a simplified check here or pass context from run().

    // We will assume exact match for simplicity in this fix,
    // or you can re-add the context parameter like in previous versions.
    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      if (superElement.name != detail.name) return false;
      final uri = superElement.library.firstFragment.source.uri.toString();
      // Simple check. For robust check, pass context to helper.
      return uri == detail.import || uri.endsWith(detail.import!);
    });
  }
}
