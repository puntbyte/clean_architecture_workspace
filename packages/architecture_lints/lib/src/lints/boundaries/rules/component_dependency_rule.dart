import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/import_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ComponentDependencyRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_dep_component',
    problemMessage: 'Dependency Violation: {0} cannot depend on {1}.',
    correctionMessage: 'Remove the dependency to maintain architectural boundaries.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const ComponentDependencyRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    if (component == null) return;

    // 1. Filter rules: Ask the component if it matches the 'on' clause
    final rules = config.dependencies.where((rule) {
      return component.matchesAny(rule.onIds);
    }).toList();

    if (rules.isEmpty) return;

    // Helper to validate a specific dependency target
    void checkViolation({
      required ComponentContext targetComponent,
      required Object nodeOrToken, // AstNode or Token
    }) {
      // Allow self-references (same component definition)
      if (component.id == targetComponent.id) return;

      for (final rule in rules) {
        // A. Check Forbidden (Blacklist)
        // Ask the TARGET component if it matches the forbidden list
        if (targetComponent.matchesAny(rule.forbidden.components)) {
          _report(
            reporter: reporter,
            nodeOrToken: nodeOrToken,
            current: component,
            target: targetComponent,
          );
          return;
        }

        // B. Check Allowed (Whitelist)
        // If an allow list exists, the target MUST be in it.
        if (rule.allowed.components.isNotEmpty) {
          if (!targetComponent.matchesAny(rule.allowed.components)) {
            _report(
              reporter: reporter,
              nodeOrToken: nodeOrToken,
              current: component,
              target: targetComponent,
            );
          }
        }
      }
    }

    // 2. Check Imports (Directives)
    context.registry.addImportDirective((node) {
      final importedPath = ImportResolver.resolvePath(node: node);
      if (importedPath == null) return;

      final targetComponent = fileResolver.resolve(importedPath);
      if (targetComponent != null) {
        checkViolation(targetComponent: targetComponent, nodeOrToken: node.uri);
      }
    });

    // 3. Check Usages (Named Types in code)
    context.registry.addNamedType((node) {
      final element = node.element;
      if (element == null) return;

      final library = element.library;
      if (library == null || library.isInSdk || library.isDartCore) return;

      final sourcePath = library.firstFragment.source.fullName;
      final targetComponent = fileResolver.resolve(sourcePath);

      if (targetComponent != null) {
        checkViolation(targetComponent: targetComponent, nodeOrToken: node);
      }
    });
  }

  void _report({
    required DiagnosticReporter reporter,
    required Object nodeOrToken,
    required ComponentContext current,
    required ComponentContext target,
  }) {
    final args = [
      current.displayName, // Use getter from ComponentContext
      target.displayName, // Use getter from ComponentContext
    ];

    if (nodeOrToken is AstNode) {
      reporter.atNode(nodeOrToken, _code, arguments: args);
    } else if (nodeOrToken is Token) {
      reporter.atToken(nodeOrToken, _code, arguments: args);
    }
  }
}
