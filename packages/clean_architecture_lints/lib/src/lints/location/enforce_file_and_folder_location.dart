// lib/src/lints/location/enforce_file_and_folder_location.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that a class is located in the correct architectural directory
/// based on its name.
///
/// **Reasoning:** This lint prevents architectural bleed by ensuring that a class
/// whose name clearly identifies it as a specific component (e.g., `UserModel`)
/// is not accidentally placed in the wrong directory (e.g., `/entities`).
/// It cooperates with `enforce_naming_conventions` by focusing only on these
/// clear "mislocation" violations.
class EnforceFileAndFolderLocation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_file_and_folder_location',
    problemMessage: 'A {0} was found in a "{1}" directory, but it belongs in a "{2}" directory.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceFileAndFolderLocation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final allPatterns = _getAllPatterns(config.namingConventions);

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      // 1. Determine the component based on the file's directory. This is the "actual" location.
      final actualComponent = layerResolver.getComponent(filePath);
      if (actualComponent == ArchComponent.unknown) return;

      // 2. Determine the "best guess" for what this class is, based on its name.
      // This is the "expected" component.
      final expectedComponent = _getBestGuessComponent(className, allPatterns);
      if (expectedComponent == null) return;

      // 3. The violation is simple: does the expected component match the actual one?
      // We also check that the class name does NOT match the pattern for its actual location.
      // This prevents flagging `UserEntity` in an `entities` folder, as its name also
      // technically matches the `{{name}}` pattern for `usecase`.
      final ruleForActual = config.namingConventions.getRuleFor(actualComponent);
      final matchesActualPattern =
          ruleForActual != null &&
          NamingUtils.validateName(name: className, template: ruleForActual.pattern);

      if (expectedComponent != actualComponent && !matchesActualPattern) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [
            expectedComponent.label, // What the class looks like (e.g., "Model")
            actualComponent.label, // Where it was found (e.g., "Entity")
            expectedComponent.label, // Where it belongs (e.g., "Model")
          ],
        );
      }
    });
  }

  /// Creates a list of all known patterns for the mislocation check.
  List<_ComponentPattern> _getAllPatterns(NamingConventionsConfig naming) {
    return naming.rules.entries
        .map((entry) => _ComponentPattern(pattern: entry.value.pattern, component: entry.key))
        .toList();
  }

  /// Finds the best-fit architectural component for a class based on its name,
  /// prioritizing more specific patterns.
  ArchComponent? _getBestGuessComponent(String className, List<_ComponentPattern> allPatterns) {
    // Sort rules to check more specific patterns (longer templates) first.
    final sortedPatterns = List<_ComponentPattern>.from(allPatterns)
      ..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));

    final bestGuess = sortedPatterns.firstWhereOrNull(
      (p) => NamingUtils.validateName(name: className, template: p.pattern),
    );
    return bestGuess?.component;
  }
}

/// A private helper class to associate a naming pattern with its architectural component.
class _ComponentPattern {
  final String pattern;
  final ArchComponent component;

  const _ComponentPattern({required this.pattern, required this.component});
}
