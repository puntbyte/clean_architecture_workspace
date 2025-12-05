import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/import_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/boundaries/logic/component_logic.dart'; // Import Logic
import 'package:architecture_lints/src/utils/message_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ComponentDependencyRule extends ArchitectureLintRule with ComponentLogic {
  static const _code = LintCode(
    name: 'arch_dep_component',
    problemMessage: 'Dependency Violation: {0} cannot depend on {1}.',
    correctionMessage: 'Remove the dependency to maintain architectural boundaries.',
    errorSeverity: DiagnosticSeverity.ERROR,
  );

  const ComponentDependencyRule() : super(code: _code);

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

    // 1. Get rules that apply to this component (or its parents)
    // We use matchesComponent here too:
    // If component is 'domain.usecase', it matches rules for 'domain' (Prefix)
    // or 'usecase' (Suffix).
    final rules = config.dependencies.where((rule) {
      return rule.onIds.any((id) => matchesComponent([id], component.id));
    }).toList();

    if (rules.isEmpty) return;

    // Helper to validate a specific dependency target
    void checkViolation({
      required ComponentConfig targetComponent,
      required Object nodeOrToken,
    }) {
      if (component.id == targetComponent.id) return;

      for (final rule in rules) {
        // A. Check Forbidden (Blacklist)
        if (matchesComponent(rule.forbidden.components, targetComponent.id)) {
          _report(
            reporter: reporter,
            nodeOrToken: nodeOrToken,
            current: component,
            target: targetComponent,
          );
          return;
        }

        // B. Check Allowed (Whitelist)
        if (rule.allowed.components.isNotEmpty) {
          if (!matchesComponent(rule.allowed.components, targetComponent.id)) {
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

    // 2. Check Imports
    context.registry.addImportDirective((node) {
      final importedPath = ImportResolver.resolvePath(node: node);
      if (importedPath == null) return;

      final targetComponent = fileResolver.resolve(importedPath);
      if (targetComponent != null) {
        checkViolation(targetComponent: targetComponent, nodeOrToken: node.uri);
      }
    });

    // 3. Check Usages
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
    required ComponentConfig current,
    required ComponentConfig target,
  }) {
    final args = [
      MessageUtils.humanizeComponent(current), // {0}
      MessageUtils.humanizeComponent(target), // {1}
    ];

    if (nodeOrToken is AstNode) {
      reporter.atNode(nodeOrToken, _code, arguments: args);
    } else if (nodeOrToken is Token) {
      reporter.atToken(nodeOrToken, _code, arguments: args);
    }
  }
}
