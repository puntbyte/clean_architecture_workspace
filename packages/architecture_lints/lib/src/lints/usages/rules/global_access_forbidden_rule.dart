import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/enums/usage_kind.dart'; // Import Enum
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/usage_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/usages/base/usage_base_rule.dart'; // Import Base
import 'package:architecture_lints/src/lints/usages/logic/usage_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class GlobalAccessForbiddenRule extends UsageBaseRule with UsageLogic {
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
  }) {
    // 1. Pre-calculate relevant constraints
    final constraints = rules
        .expand((r) => r.forbidden)
        .where((c) => c.kind == UsageKind.access && c.definition != null)
        .toList();

    if (constraints.isEmpty) return;

    // 2. Register Identifier Listener
    context.registry.addIdentifier((node) {
      // Avoid reporting multiple times for PrefixedIdentifier (a.b)
      final parent = node.parent;
      if (parent is PropertyAccess) return;
      if (parent is PrefixedIdentifier && parent.identifier == node) return;

      for (final constraint in constraints) {
        final serviceDef = config.services[constraint.definition];
        if (serviceDef == null) continue;

        if (matchesService(node, serviceDef)) {
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