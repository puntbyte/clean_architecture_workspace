// lib/src/lints/naming/base/naming_base_rule.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

abstract class NamingBaseRule extends ArchitectureRule with InheritanceLogic {
  const NamingBaseRule({required super.code});

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    context.registry.addClassDeclaration((node) {
      // 1. Intent Detection via Inheritance
      // (This requires InheritanceLogic mixin)
      final inheritanceId = findComponentIdByInheritance(node, config, fileResolver);

      var effectiveConfig = component?.definition;

      // If inheritance dictates a specific component type, override the file-path based type.
      if (inheritanceId != null) {
        try {
          effectiveConfig = config.components.firstWhere((c) => c.id == inheritanceId);
        } catch (_) {}
      }

      if (effectiveConfig == null) return;

      checkName(
        node: node,
        config: effectiveConfig,
        reporter: reporter,
        rootConfig: config,
      );
    });
  }

  void checkName({
    required ClassDeclaration node,
    required ComponentDefinition config,
    required DiagnosticReporter reporter,
    required ArchitectureConfig rootConfig,
  });
}
