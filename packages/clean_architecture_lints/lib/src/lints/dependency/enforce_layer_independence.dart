// lib/src/lints/dependency/enforce_layer_independence.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/dependencies_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

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
    final sourceComponent = layerResolver.getComponent(resolver.source.fullName);
    if (sourceComponent == ArchComponent.unknown) return;

    final componentRule = config.dependencies.ruleFor(sourceComponent.id);
    final layerRule = config.dependencies.ruleFor(sourceComponent.layer.id);

    final rules = [?componentRule, ?layerRule];
    if (rules.isEmpty) return;

    context.registry.addImportDirective((node) {
      final uriString = node.uri.stringValue;
      if (uriString == null) return;

      // --- CHECK 1: External Packages ---
      if (uriString.startsWith('package:')) {
        for (final rule in rules) {
          for (final forbiddenPackage in rule.forbidden.packages) {
            final checkString = forbiddenPackage.endsWith('/**')
                ? forbiddenPackage.substring(0, forbiddenPackage.length - 3)
                : forbiddenPackage;

            if (uriString.startsWith(checkString)) {
              reporter.atNode(
                node.uri,
                _forbiddenPackageCode,
                arguments: [sourceComponent.label, forbiddenPackage],
              );
              return;
            }
          }
        }
      }

      // --- CHECK 2: Internal Components ---
      final importedComponent = _resolveImportedComponent(node, context);
      if (importedComponent == ArchComponent.unknown) return;

      for (final rule in rules) {
        // A. Forbidden List
        if (_isForbidden(importedComponent, rule)) {
          reporter.atNode(
            node.uri,
            _forbiddenComponentCode,
            arguments: [sourceComponent.label, importedComponent.label],
          );
          return;
        }

        // B. Allowed List
        if (rule.allowed.isNotEmpty && !_isAllowed(importedComponent, rule)) {
          reporter.atNode(
            node.uri,
            _unallowedComponentCode,
            arguments: [sourceComponent.label, importedComponent.label],
          );
          return;
        }
      }
    });
  }

  ArchComponent _resolveImportedComponent(ImportDirective node, CustomLintContext context) {
    // Strategy A: Semantic Resolution
    final importedLibrary = node.libraryImport?.importedLibrary;
    final source = importedLibrary?.firstFragment.source;

    if (source != null) {
      return layerResolver.getComponent(source.fullName);
    }

    // Strategy B: String-based Fallback
    final uriString = node.uri.stringValue;
    if (uriString != null && uriString.startsWith('package:${context.pubspec.name}/')) {
      // features/auth/data/models/user_model.dart
      final relativePath = uriString.replaceFirst('package:${context.pubspec.name}/', '');

      // We construct a fake path that LayerResolver can understand.
      // LayerResolver typically looks for 'lib/' in the path to anchor itself.
      // Using p.posix ensures forward slashes which are easier for logic handling,
      // though LayerResolver likely normalizes internally.
      final fakePath = p.posix.join('/root/lib', relativePath);

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
