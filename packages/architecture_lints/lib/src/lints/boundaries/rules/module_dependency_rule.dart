import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/import_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/boundaries/logic/module_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ModuleDependencyRule extends ArchitectureLintRule with ModuleLogic {
  static const _code = LintCode(
    name: 'arch_dep_module',
    problemMessage: 'Module Isolation Violation: {0} "{1}" cannot import {0} "{2}".',
    correctionMessage:
        'Sibling modules must remain independent. Use a shared module or an abstraction layer.',
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
    ComponentContext? component,
  }) {
    // 1. Identify Current Module
    // If we have a ComponentContext, we trust its module logic.
    // If not (orphan file inside a feature), we try to resolve the module manually.
    var currentModule = component?.module;
    currentModule ??= resolveModuleContext(resolver.path, config.modules);

    // Only strictly isolated modules matter here
    if (currentModule == null || !currentModule.isStrict) return;

    context.registry.addImportDirective((node) {
      // 2. Resolve Import
      final importedPath = ImportResolver.resolvePath(node: node);
      if (importedPath == null) return;

      // 3. Identify Imported Module
      // Again, try ComponentContext first if possible (requires FileResolver to return Context)
      final importedComponent = fileResolver.resolve(importedPath);

      var importedModule = importedComponent?.module;
      importedModule ??= resolveModuleContext(importedPath, config.modules);

      if (importedModule == null) return;

      // 4. Check Isolation (Logic encapsulated in ModuleContext)
      if (!currentModule!.canImport(importedModule)) {
        // Capitalize key for display (e.g. 'features' -> 'Features')
        final typeName = currentModule.key.replaceFirstMapped(
          RegExp('^[a-z]'),
          (m) => m.group(0)!.toUpperCase(),
        );

        reporter.atNode(
          node.uri,
          _code,
          arguments: [
            typeName, // {0} e.g. Feature
            currentModule.name, // {1} e.g. Login
            importedModule.name, // {2} e.g. Home
          ],
        );
      }
    });
  }
}
