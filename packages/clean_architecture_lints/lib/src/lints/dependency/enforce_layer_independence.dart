// lib/src/lints/dependency/enforce_layer_independence.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/dependencies_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A generic lint that enforces the dependency graph defined in the configuration.
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
  void run(
      CustomLintResolver resolver,
      DiagnosticReporter reporter,
      CustomLintContext context,
      ) {
    if (config.dependencies.rules.isEmpty) return;

    final sourceComponent = layerResolver.getComponent(resolver.source.fullName);
    if (sourceComponent == ArchComponent.unknown) return;

    final rule = config.dependencies.ruleFor(sourceComponent.id) ??
        config.dependencies.ruleFor(sourceComponent.layer.id);

    if (rule == null) return;

    context.registry.addImportDirective((node) {
      final uriString = node.uri.stringValue;
      if (uriString == null) return;

      // 1. External Package Check (String-based)
      if (uriString.startsWith('package:')) {
        for (final forbiddenPackage in rule.forbidden.packages) {
          if (uriString.startsWith(forbiddenPackage)) {
            reporter.atNode(
              node.uri,
              _forbiddenPackageCode,
              arguments: [sourceComponent.label, forbiddenPackage],
            );
            return;
          }
        }
      }

      // 2. Internal Component Check (Resolution-based)
      final importedComponent = _resolveImportedComponent(node);
      if (importedComponent == ArchComponent.unknown) return;

      if (_isForbidden(importedComponent, rule)) {
        reporter.atNode(
          node.uri,
          _forbiddenComponentCode,
          arguments: [sourceComponent.label, importedComponent.label],
        );
        return;
      }

      if (rule.allowed.isNotEmpty && !_isAllowed(importedComponent, rule)) {
        reporter.atNode(
          node.uri,
          _unallowedComponentCode,
          arguments: [sourceComponent.label, importedComponent.label],
        );
      }
    });
  }

  ArchComponent _resolveImportedComponent(ImportDirective node) {
    // [Analyzer 8.0.0 Fix] Use `libraryImport` instead of `element`
    // `libraryImport` represents the semantic import model.
    final importedLibrary = node.libraryImport?.importedLibrary;

    final source = importedLibrary?.firstFragment.source;
    if (source == null) return ArchComponent.unknown;

    return layerResolver.getComponent(source.fullName);
  }

  bool _isForbidden(ArchComponent imported, DependencyRule rule) {
    return rule.forbidden.components.contains(imported.id) ||
        rule.forbidden.components.contains(imported.layer.id);
  }

  bool _isAllowed(ArchComponent imported, DependencyRule rule) {
    return rule.allowed.components.contains(imported.id) ||
        rule.allowed.components.contains(imported.layer.id);
  }
}