import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/enums/usage_kind.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/usage_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/domain/definition_context.dart';
import 'package:architecture_lints/src/lints/usages/base/usage_base_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class GlobalAccessForbiddenRule extends UsageBaseRule {
  static const _code = LintCode(
    name: 'arch_usage_global_access',
    problemMessage: 'Global access to "{0}" is forbidden in this layer.',
    correctionMessage: 'Use Dependency Injection instead of direct access.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const GlobalAccessForbiddenRule() : super(code: _code);

  @override
  void registerListeners({
    required CustomLintContext context,
    required List<UsageConfig> rules,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    required DiagnosticReporter reporter,
    required ComponentContext component,
  }) {
    final constraints = rules
        .expand((r) => r.forbidden)
        .where((c) => c.kind == UsageKind.access && c.definition != null)
        .toList();

    if (constraints.isEmpty) return;

    context.registry.addIdentifier((node) {
      final parent = node.parent;
      if (parent is PropertyAccess) return;
      if (parent is PrefixedIdentifier) {
        if (parent.identifier == node) return;
      }

      for (final constraint in constraints) {
        final definition = config.definitions[constraint.definition];
        if (definition == null) continue;

        // Wrap on-the-fly in Context
        final symbolContext = DefinitionContext(
          key: constraint.definition!,
          definition: definition,
        );

        if (symbolContext.matchesUsage(node)) {
          reporter.atNode(
            node,
            _code,
            arguments: [constraint.definition!],
          );
          return;
        }
      }
    });
  }
}
