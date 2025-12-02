// lib/src/lints/naming/class_naming_lint.dart

import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/lints/architecture_lint.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class ClassNamingLint extends ArchitectureLint {
  static const LintCode _patternCode = LintCode(
    name: 'arch_class_naming',
    problemMessage: 'The name `{0}` does not match the required `{1}` pattern for a {2}.',
  );

  static const LintCode _antipatternCode = LintCode(
    name: 'arch_antipattern_naming',
    problemMessage: 'The name `{0}` uses a forbidden pattern `{1}`.',
  );

  const ClassNamingLint() : super(code: _patternCode);

  @override
  void run(
      CustomLintResolver resolver,
      DiagnosticReporter reporter,
      CustomLintContext context,
      ) {
    context.registry.addClassDeclaration((node) {
      final config = getConfig();
      if (config == null) {
        // Report config error only once (handled by ProjectStructureLint usually),
        // but we can add a debug print here or fail silently to avoid noise.
        return;
      }

      final path = resolver.path;
      final component = getComponentFromFile(config, path);

      // If component is null, it's an Orphan.
      // ProjectStructureLint handles orphans. We should ignore them here.
      if (component == null) return;

      // If this component has no naming rules, we are done.
      if (component.pattern == null && component.antipattern == null) return;

      final className = node.name.lexeme;

      // 1. Check Antipattern (High Priority)
      // e.g. UserEntity -> matches {{name}}Entity -> Error
      if (component.isForbiddenName(className)) {
        reporter.atToken(
          node.name,
          _antipatternCode,
          arguments: [className, component.antipattern!],
        );
        return; // Don't check pattern if it's already explicitly forbidden
      }

      // 2. Check Pattern (Requirement)
      // e.g. AuthService -> does not match {{name}}Repository -> Error
      if (!component.isValidName(className)) {
        reporter.atToken(
          node.name,
          _patternCode,
          arguments: [className, component.pattern!, component.name],
        );
      }
    });
  }
}