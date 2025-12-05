import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/exception_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/lints/safety/logic/exception_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class ExceptionBaseRule extends ArchitectureLintRule
    with ExceptionLogic, InheritanceLogic {
  const ExceptionBaseRule({required super.code});

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentConfig? component,
  }) {
    if (component == null) return;

    // 1. Centralized Config Filtering
    final rules = config.exceptions.where((rule) {
      return rule.onIds.any((id) => componentMatches(id, component.id));
    }).toList();

    if (rules.isEmpty) return;

    // 2. Register Listeners
    // We register both; subclasses will only implement the one they need.

    context.registry.addMethodDeclaration((node) {
      // Skip abstract methods or empty bodies
      if (node.body is EmptyFunctionBody) return;

      checkMethod(
        node: node,
        rules: rules,
        config: config,
        reporter: reporter,
      );
    });

    context.registry.addCatchClause((node) {
      checkCatch(
        node: node,
        rules: rules,
        config: config,
        reporter: reporter,
      );
    });
  }

  // --- Extension Points ---

  /// Override to enforce rules on method bodies (Forbidden operations, Required flow).
  void checkMethod({
    required MethodDeclaration node,
    required List<ExceptionConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
  }) {}

  /// Override to enforce rules on catch blocks (Conversions).
  void checkCatch({
    required CatchClause node,
    required List<ExceptionConfig> rules,
    required ArchitectureConfig config,
    required DiagnosticReporter reporter,
  }) {}
}