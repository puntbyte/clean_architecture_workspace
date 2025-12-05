import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/lints/usages/logic/usage_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class GlobalAccessForbiddenRule extends ArchitectureLintRule with InheritanceLogic, UsageLogic {
  static const _code = LintCode(
    name: 'arch_usage_global_access',
    problemMessage: 'Global access to "{0}" is forbidden in this layer.',
    correctionMessage: 'Use Dependency Injection instead of direct access.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const GlobalAccessForbiddenRule() : super(code: _code);

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

    final rules = config.usages.where((rule) {
      return rule.onIds.any((id) => componentMatches(id, component.id));
    }).toList();

    if (rules.isEmpty) return;

    // Filter relevant forbidden constraints
    final constraints = rules
        .expand((r) => r.forbidden)
        .where((c) => c.kind == 'access' && c.definition != null)
        .toList();

    if (constraints.isEmpty) return;

    context.registry.addIdentifier((node) {
      // Avoid reporting multiple times for PrefixedIdentifier (a.b)
      // We only care about the root or the full identifier usage
      final parent = node.parent;
      if (parent is PropertyAccess) return;

      // FIX: Safer checking without direct casting if possible, or explicit variable capture
      if (parent is PrefixedIdentifier) {
        if (parent.identifier == node) return;
      }

      for (final constraint in constraints) {
        final serviceDef = config.services[constraint.definition];
        if (serviceDef == null) continue;

        if (matchesService(node, serviceDef)) {
          reporter.atNode(
            node,
            _code,
            arguments: [constraint.definition!],
          );
          return; // Stop after first match
        }
      }
    });
  }
}