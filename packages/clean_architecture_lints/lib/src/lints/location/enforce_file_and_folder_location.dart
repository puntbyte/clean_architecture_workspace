// lib/src/lints/location/enforce_file_and_folder_location.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces that a class is located in the correct architectural
/// directory based on its name.
class EnforceFileAndFolderLocation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_file_and_folder_location',
    problemMessage: 'A {0} was found in a "{1}" directory, but it belongs in a "{2}" directory.',
    correctionMessage: 'Move this file to the correct directory or rename the class.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final List<_ComponentPattern> _sortedPatterns;

  EnforceFileAndFolderLocation({
    required super.config,
    required super.layerResolver,
  }) : _sortedPatterns = _createSortedPatterns(config.namingConventions.rules),
        super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (_sortedPatterns.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      final actualComponent = layerResolver.getComponent(filePath);
      if (actualComponent == ArchComponent.unknown) return;

      // 1. Find the BEST match (longest/most specific pattern).
      final bestMatch = _sortedPatterns.firstWhereOrNull(
            (p) => NamingUtils.validateName(name: className, template: p.pattern),
      );

      if (bestMatch == null) return; // Name doesn't match anything known

      // 2. If the best guess matches the actual location, we are good.
      if (bestMatch.component == actualComponent) return;

      // 3. Collision Handling:
      // If the actual component matches BUT the pattern was weaker (shorter) than the bestMatch,
      // it is likely a misnamed/misplaced file.
      // Example: 'UserModel' inside 'entities'.
      //   - bestMatch: Model ('{{name}}Model', len 13)
      //   - actual: Entity ('{{name}}', len 8)
      //   - Result: 8 < 13 -> VIOLATION.
      //
      // Example: 'Login' inside 'usecases'.
      //   - bestMatch: Entity ('{{name}}', len 8) (assuming sorted order)
      //   - actual: Usecase ('{{name}}', len 8)
      //   - Result: 8 >= 8 -> AMBIGUOUS -> NO VIOLATION.

      final isAmbiguousOrValid = _sortedPatterns.any((p) =>
      p.component == actualComponent &&
          NamingUtils.validateName(name: className, template: p.pattern) &&
          p.pattern.length >= bestMatch.pattern.length);

      if (isAmbiguousOrValid) return;

      reporter.atToken(
        node.name,
        _code,
        arguments: [
          bestMatch.component.label, // e.g. "Model"
          actualComponent.label,     // e.g. "Entity"
          bestMatch.component.label, // e.g. "Model"
        ],
      );
    });
  }

  static List<_ComponentPattern> _createSortedPatterns(List<NamingRule> rules) {
    final patterns = rules.expand((rule) {
      return rule.on.map((componentId) {
        final component = ArchComponent.fromId(componentId);
        return component != ArchComponent.unknown
            ? _ComponentPattern(pattern: rule.pattern, component: component)
            : null;
      });
    }).whereNotNull().toList();

    // Sort by pattern length descending.
    // Longer patterns usually imply higher specificity (e.g. "UserModel" > "User").
    patterns.sort((a, b) => b.pattern.length.compareTo(a.pattern.length));

    return patterns;
  }
}

class _ComponentPattern {
  final String pattern;
  final ArchComponent component;
  const _ComponentPattern({required this.pattern, required this.component});
}