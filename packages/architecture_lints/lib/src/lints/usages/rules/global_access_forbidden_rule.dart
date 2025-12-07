import 'package:analyzer/dart/ast/ast.dart';
// Hide LintCode to avoid conflict with custom_lint_builder
import 'package:analyzer/error/error.dart' hide LintCode;
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

      // --- 1. FILTERING (AST Noise Reduction) ---

      // Case A: Property Access (obj.prop)
      // We only want to check 'obj'. If 'node' is 'prop', skip it.
      if (parent is PropertyAccess && parent.propertyName == node) return;

      // Case B: Prefixed Identifier (prefix.id)
      // e.g. GetIt.I -> Check 'GetIt', skip 'I'.
      if (parent is PrefixedIdentifier && parent.identifier == node) return;

      // Case C: Method Invocation (obj.method())
      // Check 'obj', skip 'method'.
      if (parent is MethodInvocation && parent.methodName == node) return;

      // Case D: Declaration Usage (e.g. "class GetIt {}")
      if (parent is ClassDeclaration || parent is VariableDeclaration) return;
      if (parent is ConstructorDeclaration) return;

      // Case E: Type Annotations (e.g. final GetIt locator;)
      // We flag *access* (values), not type references.
      if (parent is NamedType) return;

      // -------------------------------------------

      for (final constraint in constraints) {
        final definition = config.definitions[constraint.definition];
        if (definition == null) continue;

        final symbolContext = DefinitionContext(
          key: constraint.definition!,
          definition: definition,
        );

        if (symbolContext.matchesUsage(node)) {
          // FIX: Use the actual node name (e.g., "locator", "GetIt") for the message
          // instead of the internal config key ("service.locator").
          final displayName = node.name;

          reporter.atNode(
            node,
            _code,
            arguments: [displayName],
          );
          // Stop after first match
          return;
        }
      }
    });
  }
}