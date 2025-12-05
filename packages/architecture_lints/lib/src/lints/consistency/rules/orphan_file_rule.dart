import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart'; // Import PathMatcher
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class OrphanFileRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_orphan_file',
    problemMessage: '{0}',
    correctionMessage: 'Move this file to a valid folder defined in architecture.yaml.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const OrphanFileRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    // 1. If it matches a Component, it is valid.
    if (component != null) return;

    // 2. Check Excludes (Configurable ignores)
    // We use PathMatcher because it supports wildcards (*) defined in the config.
    // e.g. '*.g.dart', 'lib/main.dart'
    for (final pattern in config.excludes) {
      // We assume PathMatcher.matches handles glob-like patterns
      if (PathMatcher.matches(resolver.path, pattern)) {
        return;
      }
    }

    // 3. Check if it belongs to a Module
    final moduleContext = fileResolver.resolveModule(resolver.path);

    context.registry.addCompilationUnit((node) {
      if (moduleContext != null) {
        // Case A: Inside a Module, but not a known Component
        reporter.atNode(
          _findReportTarget(node),
          _code,
          arguments: [
            'This file is inside module "${moduleContext.name}" (${moduleContext.key}) but does not match any Component pattern.',
          ],
        );
      } else {
        // Case B: Completely Outside
        reporter.atNode(
          _findReportTarget(node),
          _code,
          arguments: [
            'This file does not belong to any defined Module or Component in the architecture.',
          ],
        );
      }
    });
  }

  AstNode _findReportTarget(CompilationUnit unit) {
    if (unit.directives.isNotEmpty) return unit.directives.first;
    if (unit.declarations.isNotEmpty) return unit.declarations.first;
    return unit;
  }
}
