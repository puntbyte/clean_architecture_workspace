import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class OrphanFileRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_orphan_file',
    problemMessage: 'This file does not belong to any defined architectural component.',
    correctionMessage: 'Move this file to a valid folder defined in architecture.yaml.',
  );

  const OrphanFileRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    ComponentConfig? component,
  }) {
    // If a component WAS resolved, this file is fine. Return.
    if (component != null) return;

    // Ignore generated files explicitly (common noise)
    if (resolver.path.endsWith('.g.dart') || resolver.path.endsWith('.freezed.dart')) {
      return;
    }

    // If we are here, the FileResolver returned null for this file path.
    context.registry.addCompilationUnit((node) {
      reporter.atNode(node, _code);
    });
  }
}
