// lib/src/lints/purity/disallow_flutter_in_domain.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids any dependency on the Flutter SDK within the domain layer.
///
/// **Category:** Purity
///
/// **Reasoning:** The domain layer must be pure and platform-independent to ensure
/// business logic is decoupled from the UI framework. Dependencies on `dart:ui`
/// or `package:flutter` make the domain layer hard to test and tightly coupled
/// to specific platforms.
class DisallowFlutterInDomain extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_flutter_in_domain',
    problemMessage: 'Domain layer purity violation: Do not depend on the Flutter SDK.',
    correctionMessage: 'Remove the Flutter dependency and use pure Dart types or domain objects.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowFlutterInDomain({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);

    // FIX: Use the new `layer` getter to check if this file belongs to the domain.
    if (component.layer != ArchComponent.domain) return;

    // 1. Check for forbidden import statements (Explicit check).
    context.registry.addImportDirective((node) {
      final importUri = node.uri.stringValue;
      if (importUri != null) {
        if (importUri.startsWith('package:flutter/') || importUri == 'dart:ui') {
          reporter.atNode(node, _code);
        }
      }
    });

    // 2. Check for forbidden types in code (Implicit check).
    // Using addTypeAnnotation catches fields, methods, params, variables, and generics.
    context.registry.addTypeAnnotation((node) {
      final type = node.type;
      if (type == null) return;

      // Get the source library of the element being used.
      final element = type.element;
      final uri = element?.library?.firstFragment.source.uri;

      if (uri != null) {
        final isFlutter = uri.isScheme('package') && uri.pathSegments.firstOrNull == 'flutter';
        final isDartUi = uri.isScheme('dart') && uri.pathSegments.firstOrNull == 'ui';

        if (isFlutter || isDartUi) {
          reporter.atNode(node, _code);
        }
      }
    });
  }
}
