// lib/src/lints/structure/project_structure_lint.dart

/*import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/parsing/config_loader.dart';
import 'package:architecture_lints/src/lints/architecture_lint.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;

class ProjectStructureLint extends ArchitectureLint {
  static const LintCode _code = LintCode(
    name: 'arch_orphan_file',
    problemMessage: 'This file does not belong to any defined architectural component.',
    correctionMessage: 'Move this file to a directory defined in architecture.yaml.',
  );

  const ProjectStructureLint() : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      final config = getConfig();

      // DEBUGGING: If config is null, show the specific error from loader
      if (config == null) {
        final errorMessage = ConfigLoader.loadError ?? 'Unknown error loading configuration.';

        // Dynamically create a code with the specific error message
        reporter.atNode(
          node,
          LintCode(
            name: 'arch_config_error',
            problemMessage: errorMessage,
          ),
        );
        return;
      }

      final path = resolver.path;

      // Filter exclusions
      if (!path.contains('lib')) return;
      if (path.endsWith('.g.dart')) return;
      if (path.endsWith('.freezed.dart')) return;
      if (p.basename(path) == 'main.dart') return;

      // Check Architecture
      final component = getComponentFromFile(config, path);

      // Report Error if Orphan
      if (component == null) reporter.atNode(node, _code);
    });
  }
}*/
