// lib/srcs/lints/contract/enforce_custom_inheritance.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A generic lint that enforces all custom inheritance rules defined in the
/// `inheritances` block of the configuration.
///
/// It supports `required`, `forbidden`, and `allowed` checks. The `allowed`
/// list acts as an override; if a class matches an `allowed` supertype,
/// no `required` or `forbidden` checks are performed.
class EnforceCustomInheritance extends ArchitectureLintRule {
  static const _requiredCode = LintCode(
    name: 'custom_inheritance_required',
    problemMessage: 'This {0} must extend or implement one of: `{1}`.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _forbiddenCode = LintCode(
    name: 'custom_inheritance_forbidden',
    problemMessage: 'This {0} must not extend or implement `{1}`.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final Map<String, InheritanceRule> _rules;

  EnforceCustomInheritance({required super.config, required super.layerResolver})
    : _rules = {for (final rule in config.inheritances.rules) rule.on: rule},
      super(code: _requiredCode);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (_rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final classElement = node.declaredFragment?.element;
      if (classElement == null || classElement.isAbstract) return;

      final component = layerResolver.getComponent(
        resolver.source.fullName,
        className: node.name.lexeme,
      );
      if (component == ArchComponent.unknown) return;

      final rule = _rules[component.id];
      if (rule == null) return;

      // --- 1. CHECK FOR ALLOWED (OVERRIDE) ---
      if (rule.allowed.isNotEmpty) {
        final hasAllowed = rule.allowed.any(
          (allowed) => _hasSupertype(classElement, allowed, context),
        );
        if (hasAllowed) {
          return; // This class is explicitly allowed, so we're done.
        }
      }

      // --- 2. CHECK FOR REQUIRED INHERITANCE ---
      if (rule.required.isNotEmpty) {
        final hasRequired = rule.required.any((req) => _hasSupertype(classElement, req, context));
        if (!hasRequired) {
          final requiredNames = rule.required.map((r) => r.name).join(' or ');
          reporter.atToken(node.name, _requiredCode, arguments: [component.label, requiredNames]);
        }
      }

      // --- 3. CHECK FOR FORBIDDEN INHERITANCE ---
      for (final forbidden in rule.forbidden) {
        if (_hasSupertype(classElement, forbidden, context)) {
          reporter.atToken(node.name, _forbiddenCode, arguments: [component.label, forbidden.name]);
        }
      }
    });
  }

  /// A semantic helper to check if a class element has a specific supertype.
  bool _hasSupertype(ClassElement element, InheritanceDetail detail, CustomLintContext context) {
    final expectedUri = _buildExpectedUri(detail.import, context);
    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      return superElement.name == detail.name && libraryUri == expectedUri;
    });
  }

  String _buildExpectedUri(String configPath, CustomLintContext context) {
    if (configPath.startsWith('package:')) return configPath;
    final packageName = context.pubspec.name;
    final sanitizedPath = configPath.startsWith('lib/') ? configPath.substring(4) : configPath;
    return 'package:$packageName/$sanitizedPath';
  }
}
