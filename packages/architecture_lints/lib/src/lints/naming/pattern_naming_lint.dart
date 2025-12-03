// lib/src/lints/naming/pattern_naming_lint.dart

import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/parsing/config_loader.dart';
import 'package:architecture_lints/src/lints/architecture_lint.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/*class PatternNamingLint extends ArchitectureLint {
  static const LintCode _code = LintCode(
    name: 'arch_pattern_naming',
    problemMessage: 'The name `{0}` does not match the required `{1}` pattern for a {2}.',
  );

  const PatternNamingLint() : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final config = getConfig();
      if (config == null) {
        // We report config errors here too, just in case this is the only lint enabled
        final errorMessage = ConfigLoader.loadError ?? 'Unknown error loading configuration.';
        reporter.atNode(
          node,
          LintCode(name: 'arch_config_error', problemMessage: errorMessage),
        );
        return;
      }

      final path = resolver.path;
      final component = getComponentFromFile(config, path);

      if (component == null) return;
      if (component.pattern == null) return;

      final className = node.name.lexeme;

      // Check Pattern
      if (!component.isValidName(className)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [className, component.pattern!, component.name],
        );
      }
    });
  }
}*/
