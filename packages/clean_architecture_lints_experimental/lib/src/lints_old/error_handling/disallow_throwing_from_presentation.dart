// lib/src/lints/error_handling/disallow_throwing_from_presentation.dart

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/models/configs/error_handlers_config.dart';
import 'package:architecture_lints/src/models/configs/type_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids `throw` and `rethrow` expressions in the presentation layer
/// based on the `error_handlers` configuration.
class DisallowThrowingFromPresentation extends ArchitectureRule {
  static const _code = LintCode(
    name: 'disallow_throwing_from_presentation',
    problemMessage: 'Presentation layer must not throw or rethrow exceptions.',
    correctionMessage: 'Catch the error and update the state to show a user-friendly message.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowThrowingFromPresentation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final component = layerResolver.getComponent(resolver.source.fullName);

    // 1. Scope Check: Only run if we are in the Presentation Layer
    if (component.layer != ArchComponent.presentation) return;

    // 2. Config Lookup: Find the error handler rule for this component/layer
    final rule =
        definition.errorHandlers.ruleFor(component) ??
        definition.errorHandlers.ruleFor(component.layer);

    if (rule == null) return;

    // 3. Enforce 'throw' prohibitions
    context.registry.addThrowExpression((node) {
      if (_isOperationForbidden('throw', rule, node.expression.staticType)) {
        reporter.atNode(node, _code);
      }
    });

    // 4. Enforce 'rethrow' prohibitions
    context.registry.addRethrowExpression((node) {
      // Rethrow doesn't have an explicit type operand, so we check if the operation is banned globally
      if (_isOperationForbidden('rethrow', rule, null)) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _isOperationForbidden(String opName, ErrorHandlerRule rule, DartType? thrownType) {
    for (final forbidden in rule.forbidden) {
      if (!forbidden.operations.contains(opName)) continue;

      // If no specific target type is defined in the ban, it bans ALL usages.
      if (forbidden.targetType == null) return true;

      // If 'rethrow', we can't check the type easily, so we assume it matches.
      if (thrownType == null) return true;

      // Check if the thrown type matches the configured target type (e.g. 'exception.raw')
      final targetTypeDef = definition.typeDefinitions.get(forbidden.targetType!);
      if (targetTypeDef != null && _matchesType(thrownType, targetTypeDef)) {
        return true;
      }
    }
    return false;
  }

  bool _matchesType(DartType type, TypeRule definition) {
    final element = type.element;
    if (element == null) return false;

    // Check Name match
    if (element.name != definition.name) return false;

    // Check Import match (if defined in config)
    if (definition.import != null) {
      final source = element.library?.firstFragment.source;
      if (source == null) return false;

      // Normalize standard dart:core types which might not need explicit import check
      // FIX: Replaced `isInSystemLibrary` with `uri.isScheme('dart')`
      if (source.uri.isScheme('dart') && definition.import!.startsWith('dart:')) {
        return source.uri.toString() == definition.import;
      }

      // Allow basic suffix matching to handle package URI variations
      return source.uri.toString().endsWith(definition.import!);
    }

    // If no import specified in config, name match is sufficient (e.g. 'Exception' from dart:core)
    return true;
  }
}
