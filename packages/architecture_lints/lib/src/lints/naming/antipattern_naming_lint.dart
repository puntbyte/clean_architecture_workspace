// lib/src/lints/naming/antipattern_naming_lint.dart

/*import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/lints/architecture_lint.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AntipatternNamingLint extends ArchitectureLint {
  static const LintCode _code = LintCode(
    name: 'arch_antipattern_naming',
    problemMessage: 'The name `{0}` uses a forbidden pattern `{1}`.',
  );

  const AntipatternNamingLint() : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final config = getConfig();
      if (config == null) return; // ProjectStructureLint handles config errors

      final path = resolver.path;
      final component = getComponentFromFile(config, path);

      if (component == null) return;
      if (component.antipattern == null) return;

      final className = node.name.lexeme;

      // Check Antipattern
      if (component.isForbiddenName(className)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [className, component.antipattern!],
        );
      }
    });
  }
}*/
