// lib/srcs/lints/contract/enforce_inheritance.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A generic lint that enforces all custom inheritance rules defined in the
/// `inheritances` block of the configuration.
class EnforceCustomInheritance extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_inheritance',
    problemMessage: 'Inheritance contract violation.',
  );

  // This lint uses dynamic lint codes, so the base code is generic.
  const EnforceInheritance({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // If there are no custom rules defined by the user, this lint does nothing.
    if (config.inheritance.rules.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final classElement = node.declaredFragment?.element;
      // This lint only applies to concrete (non-abstract) classes.
      if (classElement == null || classElement.isAbstract) return;

      final component = layerResolver.getComponent(
        resolver.source.fullName,
        className: node.name.lexeme,
      );
      if (component == ArchComponent.unknown) return;

      final componentNameSnakeCase = component.name.toSnakeCase();

      // Find a custom rule that applies to this specific component.
      final rule = config.inheritance.rules.firstWhereOrNull((r) => r.on == componentNameSnakeCase);
      if (rule == null) return; // No custom rule for this component.

      // --- CHECK FOR REQUIRED INHERITANCE ---
      if (rule.required.isNotEmpty) {
        final hasRequired = rule.required.any((req) => _hasSupertype(classElement, req, context));
        if (!hasRequired) {
          final requiredNames = rule.required.map((r) => r.name).join(' or ');
          reporter.atToken(
            node.name,
            LintCode(
              name: 'custom_inheritance_required',
              problemMessage: 'This ${component.label} must be a subtype of `$requiredNames`.',
              errorSeverity: DiagnosticSeverity.WARNING,
            ),
          );
        }
      }

      // --- CHECK FOR FORBIDDEN INHERITANCE ---
      for (final forbidden in rule.forbidden) {
        if (_hasSupertype(classElement, forbidden, context)) {
          reporter.atToken(
            node.name,
            LintCode(
              name: 'custom_inheritance_forbidden',
              problemMessage:
              'This ${component.label} must not be a subtype of `${forbidden.name}`.',
              errorSeverity: DiagnosticSeverity.WARNING,
            ),
          );
        }
      }

      // --- CHECK FOR SUGGESTED INHERITANCE ---
      for (final suggested in rule.suggested) {
        if (!_hasSupertype(classElement, suggested, context)) {
          reporter.atToken(
            node.name,
            LintCode(
              name: 'custom_inheritance_suggested',
              problemMessage:
              'Consider making this ${component.label} a subtype of `${suggested.name}` for '
                  'better functionality.',
            ),
          );
        }
      }
    });
  }

  /// A semantic helper to check if a class element has a specific supertype
  /// by comparing both its name and its library URI.
  bool _hasSupertype(ClassElement element, InheritanceDetail detail, CustomLintContext context) {
    final expectedUri = _buildExpectedUri(detail.import, context);

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      return superElement.name == detail.name && superElement.library.uri.toString() == expectedUri;
    });
  }

  /// A helper to construct the full `package:` URI from the configuration.
  String _buildExpectedUri(String configPath, CustomLintContext context) {
    if (configPath.startsWith('package:')) {
      return configPath;
    }
    final packageName = context.pubspec.name;
    final sanitizedPath = configPath.startsWith('/') ? configPath.substring(1) : configPath;
    return 'package:$packageName/$sanitizedPath';
  }
}
