// lib/srcs/lints/enforce_inheritance.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/models/rules/inheritance_rule.dart';
import 'package:clean_architecture_kit/src/utils/extensions/string_extension.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A single, powerful lint that enforces all inheritance rules defined in the
/// `inheritances` block of the configuration.
class EnforceInheritance extends CleanArchitectureLintRule {
  const EnforceInheritance({required super.config, required super.layerResolver,})
      : super(code: const LintCode(name: 'enforce_inheritance', problemMessage: 'Inheritance contract violation.'));

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer == ArchSubLayer.unknown) return;

    final subLayerNameSnakeCase = subLayer.name.toSnakeCase();

    // Find the inheritance rule for the current file's sub-layer.
    final rule = config.inheritance.firstWhere(
          (r) => r.on == subLayerNameSnakeCase,
      orElse: () => null,
    );

    if (rule == null) return;

    context.registry.addClassDeclaration((node) {
      final classElement = node.declaredFragment?.element;
      if (classElement == null || classElement.isAbstract) return;

      // --- CHECK FOR REQUIRED INHERITANCE ---
      if (rule.required.isNotEmpty) {
        final hasRequired = rule.required.any(
                (req) => _hasSupertype(classElement, req, context)
        );
        if (!hasRequired) {
          final requiredNames = rule.required.map((r) => r.name).join(' or ');
          reporter.atToken(
            node.name,
            LintCode(
              name: 'enforce_inheritance_required',
              problemMessage: 'This ${subLayer.label} must be a subtype of `$requiredNames`.',
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
              name: 'enforce_inheritance_forbidden',
              problemMessage: 'This ${subLayer.label} must not be a subtype of `${forbidden.name}`.',
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
              name: 'enforce_inheritance_suggested',
              problemMessage: 'Consider making this ${subLayer.label} a subtype of `${suggested.name}` for better functionality.',
              errorSeverity: DiagnosticSeverity.INFO,
            ),
          );
        }
      }
    });
  }

  /// A semantic helper to check if a class element has a specific supertype.
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