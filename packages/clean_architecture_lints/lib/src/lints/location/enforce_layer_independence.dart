// lib/src/lints/dependency/enforce_layer_independence.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/locations_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A generic lint that enforces the dependency graph defined in the `locations` configuration.
class EnforceLayerIndependence extends ArchitectureLintRule {
  static const _forbiddenComponentCode = LintCode(
    name: 'enforce_layer_independence_forbidden_component',
    problemMessage: 'Invalid import: A {0} must not import from a {1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _forbiddenPackageCode = LintCode(
    name: 'enforce_layer_independence_forbidden_package',
    problemMessage: 'Invalid import: A {0} must not import the package `{1}`.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _unallowedComponentCode = LintCode(
    name: 'enforce_layer_independence_unallowed_component',
    problemMessage: 'Invalid import: A {0} is not allowed to import from a {1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceLayerIndependence({
    required super.config,
    required super.layerResolver,
  }) : super(code: _forbiddenComponentCode);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (config.locations.rules.isEmpty) return;

    final sourceComponent = layerResolver.getComponent(resolver.source.fullName);
    if (sourceComponent == ArchComponent.unknown) return;

    final rule =
        config.locations.ruleFor(sourceComponent.id) ??
        config.locations.ruleFor(sourceComponent.layer.id);
    if (rule == null) return;

    context.registry.addImportDirective((node) {
      final importedUriString = node.uri.stringValue;
      if (importedUriString == null) return;

      final isPackageImport = importedUriString.startsWith('package:');

      // --- FORBIDDEN PACKAGE CHECK ---
      if (isPackageImport) {
        for (final forbiddenPackage in rule.forbidden.packages) {
          if (importedUriString.startsWith(forbiddenPackage)) {
            reporter.atNode(
              node.uri,
              _forbiddenPackageCode,
              arguments: [sourceComponent.label, forbiddenPackage],
            );
            return; // One violation is enough per import.
          }
        }
      }

      // --- COMPONENT CHECKS (for internal project imports) ---
      final importedComponent = _getImportedComponent(importedUriString, context);
      if (importedComponent == ArchComponent.unknown) return;

      // FORBIDDEN COMPONENT CHECK
      if (_isForbidden(importedComponent, rule)) {
        reporter.atNode(
          node.uri,
          _forbiddenComponentCode,
          arguments: [sourceComponent.label, importedComponent.label],
        );
        return;
      }

      // ALLOWED COMPONENT CHECK (only if an `allowed` block exists)
      if (rule.allowed.isNotEmpty && !_isAllowed(importedComponent, rule)) {
        reporter.atNode(
          node.uri,
          _unallowedComponentCode,
          arguments: [sourceComponent.label, importedComponent.label],
        );
      }
    });
  }

  ArchComponent _getImportedComponent(String uri, CustomLintContext context) {
    if (uri.startsWith('package:${context.pubspec.name}')) {
      // Convert `package:my_proj/features/..` to `lib/features/...` for the resolver.
      final path = uri.replaceFirst('package:${context.pubspec.name}/', 'lib/');
      return layerResolver.getComponent(path);
    }
    return ArchComponent.unknown;
  }

  bool _isForbidden(ArchComponent imported, LocationRule rule) {
    return rule.forbidden.components.contains(imported.id) ||
        rule.forbidden.components.contains(imported.layer.id);
  }

  bool _isAllowed(ArchComponent imported, LocationRule rule) {
    return rule.allowed.components.contains(imported.id) ||
        rule.allowed.components.contains(imported.layer.id);
  }
}

// Helper to get the parent layer (domain, data, presentation) of a component.
extension ArchComponentLayer on ArchComponent {
  ArchComponent get layer {
    if (ArchComponent.domainLayer.contains(this) || this == ArchComponent.domain) {
      return ArchComponent.domain;
    }
    if (ArchComponent.dataLayer.contains(this) || this == ArchComponent.data) {
      return ArchComponent.data;
    }
    if (ArchComponent.presentationLayer.contains(this) || this == ArchComponent.presentation) {
      return ArchComponent.presentation;
    }
    return ArchComponent.unknown;
  }
}
