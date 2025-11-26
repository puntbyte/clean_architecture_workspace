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
///
/// It acts as a architectural firewall, checking every import statement to ensure:
/// 1. **External Purity:** Layers like Domain do not import platform-specific packages (e.g., Flutter).
/// 2. **Internal Isolation:** Inner layers do not import Outer layers (Dependency Rule).
/// 3. **Module Boundaries:** Components adhere to strict Allowed/Forbidden rules if defined.
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
    // [1] Identify the architectural component of the current file.
    final sourceComponent = layerResolver.getComponent(resolver.source.fullName);
    if (sourceComponent == ArchComponent.unknown) return;

    // [2] Retrieve applicable rules. We look for specific component rules (e.g., 'entity') and
    // generic layer rules (e.g., 'domain').
    final componentRule = config.dependencies.ruleFor(sourceComponent.id);
    final layerRule = config.dependencies.ruleFor(sourceComponent.layer.id);

    final rules = [?componentRule, ?layerRule];

    // If no rules define dependencies for this component, we assume standard Dart behavior
    // (allow all).
    if (rules.isEmpty) return;

    // 3. Register the listener to validate imports.
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

  /// The main validation logic for a single import directive.
  ///
  /// It performs checks in order of specificity:
  /// 1. **External Package Checks:** Checks string-based URI patterns (e.g., `package:flutter/`).
  /// 2. **Internal Component Checks:** Resolves the imported file to an [ArchComponent] and checks dependency rules.
  void _validateImportDirective({
    required ImportDirective node,
    required ArchComponent sourceComponent,
    required List<DependencyRule> rules,
    required DiagnosticReporter reporter,
    required CustomLintContext context,
  }) {
    final uriString = node.uri.stringValue;
    if (uriString == null) return;

    // --- Step 1: Check for Forbidden External Packages ---
    // This checks imports like 'package:flutter/material.dart'.
    if (uriString.startsWith('package:')) {
      final hasExternalViolation = _validateExternalPackages(
        node: node,
        uriString: uriString,
        sourceComponent: sourceComponent,
        rules: rules,
        reporter: reporter,
      );

      // If an external violation is found, we stop. An import cannot be both external and internal.
      if (hasExternalViolation) return;
    }

    // --- Step 2: Check for Internal Architectural Violations ---
    // This resolves the file to see if we are importing a Model into an Entity, etc.
    _validateInternalComponents(
      node: node,
      sourceComponent: sourceComponent,
      rules: rules,
      reporter: reporter,
      context: context,
    );
  }

  /// Checks if the import URI matches any forbidden package patterns defined in the configuration.
  ///
  /// Returns `true` if a violation was found and reported.
  bool _validateExternalPackages({
    required ImportDirective node,
    required String uriString,
    required ArchComponent sourceComponent,
    required List<DependencyRule> rules,
    required DiagnosticReporter reporter,
  }) {
    for (final rule in rules) {
      for (final forbiddenPackage in rule.forbidden.packages) {
        // Handle glob-like matching from config (e.g. 'package:flutter/**')
        // We strip the '/**' suffix to perform a simple startsWith check.
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

  /// Resolves the imported file to an [ArchComponent] and validates it against
  /// Forbidden (Blacklist) and Allowed (Whitelist) rules.
  void _validateInternalComponents({
    required ImportDirective node,
    required ArchComponent sourceComponent,
    required List<DependencyRule> rules,
    required DiagnosticReporter reporter,
    required CustomLintContext context,
  }) {
    final importedComponent = _resolveImportedComponent(node, context);

    // If the imported file isn't part of our architecture (e.g. generic utility), we ignore it.
    if (importedComponent == ArchComponent.unknown) return;

    for (final rule in rules) {
      // Check A: Forbidden List (Blacklist)
      // This has higher priority. If it's explicitly forbidden, report immediately.
      if (_isForbidden(importedComponent, rule)) {
        reporter.atNode(
          node.uri,
          _code,
          arguments: [
            'Invalid import: A ${sourceComponent.label} must not import from a ${importedComponent.label}.',
          ],
        );
        return; // Stop checking other rules for this import
      }

      // Check B: Allowed List (Whitelist)
      // If an Allowed list exists, the import MUST be found within it.
      if (rule.allowed.isNotEmpty && !_isAllowed(importedComponent, rule)) {
        reporter.atNode(
          node.uri,
          _code,
          arguments: [
            'Invalid import: A ${sourceComponent.label} is not allowed to import from a ${importedComponent.label}.',
          ],
        );
        return; // Stop checking
      }
    }
  }

  /// Resolves the absolute path of the imported file to determine its [ArchComponent].
  ///
  /// Utilizes a hybrid strategy:
  /// 1. **Analyzer Resolution:** Uses the semantic model (reliable for existing files).
  /// 2. **String Fallback:** Parses `package:` URIs manually (reliable for self-references in IDEs).
  ArchComponent _resolveImportedComponent(ImportDirective node, CustomLintContext context) {
    // Strategy A: Semantic Resolution (Analyzer)
    final importedLibrary = node.libraryImport?.importedLibrary;
    final source = importedLibrary?.firstFragment.source;

    if (source != null) {
      return layerResolver.getComponent(source.fullName);
    }

    // Strategy B: String-based Fallback
    // This is critical for self-references (package:example/...) in the IDE before full analysis.
    final uriString = node.uri.stringValue;
    if (uriString != null && uriString.startsWith('package:${context.pubspec.name}/')) {
      final relativePath = uriString.replaceFirst('package:${context.pubspec.name}/', '');

      // We use system-specific separators (p.join) to construct a path that the
      // LayerResolver can understand, as it often relies on OS-specific path splitting.
      final fakeRoot = p.style == p.Style.windows ? r'C:\root\lib' : '/root/lib';

      // Combine fake root with the relative package path to simulate a real file path.
      final fakePath = p.join(fakeRoot, relativePath);

      return layerResolver.getComponent(fakePath);
    }

    return ArchComponent.unknown;
  }

  /// Checks if the [imported] component is present in the rule's forbidden list.
  bool _isForbidden(ArchComponent imported, DependencyRule rule) {
    return rule.forbidden.components.contains(imported.id) ||
        rule.forbidden.components.contains(imported.layer.id);
  }

  /// Checks if the [imported] component is present in the rule's allowed list.
  bool _isAllowed(ArchComponent imported, DependencyRule rule) {
    return rule.allowed.components.contains(imported.id) ||
        rule.allowed.components.contains(imported.layer.id);
  }
}
