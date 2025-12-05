import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/import_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/boundaries/logic/module_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ModuleDependencyRule extends ArchitectureLintRule with ModuleLogic {
  static const _code = LintCode(
    name: 'arch_dep_module',
    problemMessage: 'Module Isolation Violation: {0} "{1}" cannot import {0} "{2}".',
    correctionMessage: 'Sibling modules must remain independent. Use a shared module or an abstraction layer.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ModuleDependencyRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentConfig? component,
  }) {
    // 1. Identify which module the CURRENT file belongs to
    final currentModule = resolveModuleInstance(resolver.path, config.modules);

    // If current file is not inside a strict module (like 'features/{{name}}'), skip.
    if (currentModule == null || !currentModule.config.strict) return;

    context.registry.addImportDirective((node) {
      // 2. Resolve the IMPORTED file path
      final importedPath = ImportResolver.resolvePath(node: node);
      if (importedPath == null) return;

      // 3. Identify which module the IMPORTED file belongs to
      final importedModule = resolveModuleInstance(importedPath, config.modules);

      // If imported file is not in a module, it's likely core/shared/third-party. Allowed.
      if (importedModule == null) return;

      // 4. Check Isolation
      // Logic:
      // - Must be the SAME module definition key (e.g. both are 'features').
      // - Must have DIFFERENT instance names (e.g. 'login' vs 'home').
      if (currentModule.config.key == importedModule.config.key &&
          currentModule.name != importedModule.name) {

        reporter.atNode(
          node.uri,
          _code,
          arguments: [
            // {0} Module Type (e.g. "Feature")
            // We capitalize the key for display
            currentModule.config.key[0].toUpperCase() + currentModule.config.key.substring(1),
            // {1} Current Name
            currentModule.name,
            // {2} Imported Name
            importedModule.name
          ],
        );
      }
    });
  }
}