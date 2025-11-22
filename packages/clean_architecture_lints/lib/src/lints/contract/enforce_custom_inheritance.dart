// lib/src/lints/contract/enforce_custom_inheritance.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A generic lint that enforces all custom inheritance rules defined in the
/// `inheritances` block of the configuration.
///
/// This lint takes precedence over default presets. If a rule is defined here,
/// the corresponding preset lint (e.g., EnforceEntityContract) will skip execution.
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
         // We load ALL rules here. The presets will check if a rule exists
         // for their component and step aside if it does.
         for (final rule in config.inheritances.rules) rule.on: rule,
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

      // Identify component (e.g., 'entity', 'widget', 'manager')
      final component = layerResolver.getComponent(
        resolver.source.fullName,
        className: node.name.lexeme,
      );

      if (component == ArchComponent.unknown) return;

      // Check if there is a custom rule for this specific component
      final rule = _rules[component.id];
      if (rule == null) return;

      // 1. ALLOWED (Override)
      if (rule.allowed.isNotEmpty) {
        final isAllowed = rule.allowed.any(
          (allowed) => _hasSupertype(element, allowed, context),
        );
        if (isAllowed) return;
      }

      // 2. REQUIRED
      if (rule.required.isNotEmpty) {
        final hasRequired = rule.required.any(
          (req) => _hasSupertype(element, req, context),
        );

        if (!hasRequired) {
          final requiredNames = rule.required.map((r) => r.name).join(' or ');
          reporter.atToken(
            node.name,
            _requiredCode,
            arguments: [component.label, requiredNames],
          );
        }
      }

      // 3. FORBIDDEN
      for (final forbidden in rule.forbidden) {
        if (_hasSupertype(element, forbidden, context)) {
          reporter.atToken(
            node.name,
            _forbiddenCode,
            arguments: [component.label, forbidden.name],
          );
        }
      }
    });
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail, CustomLintContext context) {
    final expectedUri = _normalizeConfigImport(detail.import, context.pubspec.name);

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      if (superElement.name != detail.name) return false;

      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      return libraryUri == expectedUri;
    });
  }

  String _normalizeConfigImport(String importPath, String packageName) {
    if (importPath.startsWith('package:') || importPath.startsWith('dart:')) {
      return importPath;
    }
    var cleanPath = importPath;
    if (cleanPath.startsWith('lib/')) {
      cleanPath = cleanPath.substring(4);
    } else if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    return 'package:$packageName/$cleanPath';
  }
}
