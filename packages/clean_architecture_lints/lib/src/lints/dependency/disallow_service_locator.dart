// lib/src/lints/dependency/disallow_service_locator.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids the use of the Service Locator pattern (e.g., `getIt<T>()`)
/// within architectural layers.
///
/// **Category:** Dependency / Purity
///
/// **Reasoning:** Dependencies should be explicit and injected via constructors.
/// Using a global service locator hides dependencies (Dependency Hiding Anti-pattern),
/// making code harder to test and confusing to refactor.
class DisallowServiceLocator extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_service_locator',
    problemMessage:
    'Do not use a service locator. Dependencies should be explicit and injected via the '
        'constructor.',
    correctionMessage: 'Add this dependency as a constructor parameter.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowServiceLocator({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // 1. Scope: Run on all architectural components (Domain, Data, Presentation).
    // We exclude 'unknown' components (like main.dart or injection_container.dart)
    // because that is where the Service Locator is typically initialized/used legitimately.
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component == ArchComponent.unknown) return;

    // 2. Config: Get the list of banned names (e.g. 'getIt', 'sl').
    final locatorNames = config.services.dependencyInjection.serviceLocatorNames.toSet();
    if (locatorNames.isEmpty) return;

    // 3. Check: Listen for identifier usage.
    context.registry.addSimpleIdentifier((node) {
      // Check if the name matches one of the forbidden locator names.
      if (!locatorNames.contains(node.name)) return;

      // Ignore declarations (e.g. 'final getIt = ...').
      // We only want to catch *usages*.
      if (node.inDeclarationContext()) return;

      // Ignore if it is being used as a named parameter label (e.g. func(getIt: x)).
      // (Though highly unlikely a param would be named 'getIt', it's good AST hygiene).
      if (node.parent is Label) return;

      // Report the usage.
      reporter.atNode(node, _code);
    });
  }
}