import 'package:analyzer/dart/ast/ast.dart'; // For CompilationUnit
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/boundaries/logic/module_logic.dart'; // Import ModuleLogic
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

class OrphanFileRule extends ArchitectureLintRule with ModuleLogic {
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
    ComponentConfig? component,
  }) {
    // 1. If it matches a Component, it is valid.
    if (component != null) return;

    // 2. Ignore generated files and entry points
    final filename = p.basename(resolver.path);
    if (filename.endsWith('.g.dart') ||
        filename.endsWith('.freezed.dart') ||
        filename == 'main.dart' ||
        filename == 'app.dart' ||
        filename == 'firebase_options.dart') {
      return;
    }

    // 3. Check if it belongs to a Module
    final moduleInstance = resolveModuleInstance(resolver.path, config.modules);

    context.registry.addCompilationUnit((node) {
      if (moduleInstance != null) {
        // Case A: Inside a Module, but not a known Component
        // e.g. lib/features/auth/some_random_helper.dart
        final message =
            'This file is inside module "${moduleInstance.name}" '
            '(${moduleInstance.config.key}) but does not match any Component pattern.';

        reporter.atNode(
          _findReportTarget(node),
          _code,
          arguments: [message],
        );
      } else {
        // Case B: Completely Outside
        // e.g. lib/utils/random.dart (if 'utils' isn't a module)
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

  /// Helper to report the error at the top of the file (first directive or declaration)
  /// rather than underlining the entire file content which looks messy.
  AstNode _findReportTarget(CompilationUnit unit) {
    if (unit.directives.isNotEmpty) return unit.directives.first;
    if (unit.declarations.isNotEmpty) return unit.declarations.first;
    return unit;
  }
}
