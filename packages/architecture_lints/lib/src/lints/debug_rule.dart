import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';

/*
class DiagnosticsRule extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'arch_diagnostics',
    problemMessage: 'Status: {0}',
    errorSeverity: ErrorSeverity.INFO,
  );

  const DiagnosticsRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    ComponentConfig? component,
  }) {
    // We hook into the compilation unit to report at the top of the file
    context.registry.addCompilationUnit((node) {
      final status = StringBuffer();

      status.write('Config Loaded (${config.components.length} rules). ');

      if (component != null) {
        status.write('Matched Component: [${component.id}]. ');
        if (component.pattern != null) {
          status.write('Pattern: "${component.pattern}". ');
        }
      } else {
        status.write('NO COMPONENT MATCHED. ');
        status.write('Checked path: "${resolver.path}"');
      }

      reporter.atNode(node, _code, arguments: [status.toString()]);
    });
  }
}*/