// lib/src/lints/dependency/enforce_layer_independence.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/configs/dependencies_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

/// A generic lint that enforces the dependency graph defined in the configuration.
class EnforceLayerIndependence extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_layer_independence',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceLayerIndependence({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
      CustomLintResolver resolver,
      DiagnosticReporter reporter,
      CustomLintContext context,
      ) {
    final sourceComponent = layerResolver.getComponent(resolver.source.fullName);
    if (sourceComponent == ArchComponent.unknown) return;

    final componentRule = config.dependencies.ruleFor(sourceComponent.id);
    final layerRule = config.dependencies.ruleFor(sourceComponent.layer.id);

    final rules = [if (componentRule != null) componentRule, if (layerRule != null) layerRule];
    if (rules.isEmpty) return;

    context.registry.addImportDirective((node) {
      _validateImportDirective(
        node: node,
        sourceComponent: sourceComponent,
        rules: rules,
        reporter: reporter,
        context: context,
      );
    });
  }

  void _validateImportDirective({
    required ImportDirective node,
    required ArchComponent sourceComponent,
    required List<DependencyRule> rules,
    required DiagnosticReporter reporter,
    required CustomLintContext context,
  }) {
    final uriString = node.uri.stringValue;
    if (uriString == null) return;

    // --- CHECK 1: External Packages ---
    if (uriString.startsWith('package:') || uriString.startsWith('dart:')) {
      // FIX: If we are in Domain, ignore Flutter/UI imports here.
      // They are handled by the dedicated `disallow_flutter_in_domain` lint.
      if (sourceComponent.layer == ArchComponent.domain) {
        if (uriString.startsWith('package:flutter/') || uriString == 'dart:ui') {
          return;
        }
      }

      final hasExternalViolation = _validateExternalPackages(
        node: node,
        uriString: uriString,
        sourceComponent: sourceComponent,
        rules: rules,
        reporter: reporter,
      );
      if (hasExternalViolation) return;
    }

    // --- CHECK 2: Internal Components ---
    _validateInternalComponents(
      node: node,
      sourceComponent: sourceComponent,
      rules: rules,
      reporter: reporter,
      context: context,
    );
  }

  bool _validateExternalPackages({
    required ImportDirective node,
    required String uriString,
    required ArchComponent sourceComponent,
    required List<DependencyRule> rules,
    required DiagnosticReporter reporter,
  }) {
    for (final rule in rules) {
      for (final forbiddenPackage in rule.forbidden.packages) {
        final checkString = forbiddenPackage.endsWith('/**')
            ? forbiddenPackage.substring(0, forbiddenPackage.length - 3)
            : forbiddenPackage;

        if (uriString.startsWith(checkString)) {
          reporter.atNode(
            node.uri,
            _code,
            arguments: [
              'Invalid import: A ${sourceComponent.label} must not import the package `$forbiddenPackage`.',
            ],
          );
          return true;
        }
      }
    }
    return false;
  }

  void _validateInternalComponents({
    required ImportDirective node,
    required ArchComponent sourceComponent,
    required List<DependencyRule> rules,
    required DiagnosticReporter reporter,
    required CustomLintContext context,
  }) {
    final importedComponent = _resolveImportedComponent(node, context);
    if (importedComponent == ArchComponent.unknown) return;

    for (final rule in rules) {
      // A. Forbidden List
      if (_isForbidden(importedComponent, rule)) {
        reporter.atNode(
          node.uri,
          _code,
          arguments: [
            'Invalid import: A ${sourceComponent.label} must not import from a ${importedComponent.label}.',
          ],
        );
        return;
      }

      // B. Allowed List
      if (rule.allowed.isNotEmpty && !_isAllowed(importedComponent, rule)) {
        reporter.atNode(
          node.uri,
          _code,
          arguments: [
            'Invalid import: A ${sourceComponent.label} is not allowed to import from a ${importedComponent.label}.',
          ],
        );
        return;
      }
    }
  }

  ArchComponent _resolveImportedComponent(ImportDirective node, CustomLintContext context) {
    final importedLibrary = node.libraryImport?.importedLibrary;
    final source = importedLibrary?.firstFragment.source;
    if (source != null) {
      return layerResolver.getComponent(source.fullName);
    }

    // Fallback string logic for local files
    final uriString = node.uri.stringValue;
    if (uriString != null && uriString.startsWith('package:${context.pubspec.name}/')) {
      final relativePath = uriString.replaceFirst('package:${context.pubspec.name}/', '');
      final fakeRoot = p.style == p.Style.windows ? r'C:\root\lib' : '/root/lib';
      final fakePath = p.join(fakeRoot, relativePath);
      return layerResolver.getComponent(fakePath);
    }

    return ArchComponent.unknown;
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