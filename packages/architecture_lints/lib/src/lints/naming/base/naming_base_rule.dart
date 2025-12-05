import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class NamingBaseRule extends ArchitectureLintRule with InheritanceLogic {
  const NamingBaseRule({required super.code});

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentConfig? component,
  }) {
    context.registry.addClassDeclaration((node) {
      // 1. Intent Detection via Inheritance
      final inheritanceId = findComponentIdByInheritance(node, config, fileResolver);

      // 2. Determine Effective Component
      var effectiveComponent = component;
      if (inheritanceId != null) {
        try {
          effectiveComponent = config.components.firstWhere((c) => c.id == inheritanceId);
        } catch (_) {}
      }

      if (effectiveComponent == null) return;

      // 3. Delegate to implementation
      checkName(
        node: node,
        component: effectiveComponent,
        reporter: reporter,
        config: config,
      );
    });
  }

  void checkName({
    required ClassDeclaration node,
    required ComponentConfig component,
    required DiagnosticReporter reporter,
    required ArchitectureConfig config,
  });
}