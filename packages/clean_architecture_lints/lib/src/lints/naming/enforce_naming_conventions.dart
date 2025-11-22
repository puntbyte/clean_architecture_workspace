// lib/src/lints/naming/enforce_naming_conventions.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes follow the syntactic naming conventions (`pattern` and `antipattern`).
///
/// This lint cooperates with `enforce_file_and_folder_location`. It performs a
/// pre-check to guess the component type based on the class name. If the guessed
/// component does not match the component from the file's location, this lint
/// will be silent, assuming it is a mislocation issue that the other lint will handle.
class EnforceNamingConventions extends ArchitectureLintRule {
  static const _patternCode = LintCode(
    name: 'enforce_naming_conventions_pattern',
    problemMessage: 'The name `{0}` does not match the required `{1}` convention for a {2}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  static const _antiPatternCode = LintCode(
    name: 'enforce_naming_conventions_antipattern',
    problemMessage: 'The name `{0}` uses a forbidden pattern for a {1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final List<_ComponentPattern> _sortedPatterns;

  EnforceNamingConventions({required super.config, required super.layerResolver})
      : _sortedPatterns = _createSortedPatterns(config.namingConventions.rules),
        super(code: _patternCode);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (_sortedPatterns.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      final actualComponent = layerResolver.getComponent(filePath, className: className);
      if (actualComponent == ArchComponent.unknown) return;

      final rule = config.namingConventions.getRuleFor(actualComponent);
      if (rule == null) return;

      // --- Pre-Check for Mislocation ---
      // If the class name clearly indicates a different component (that is more specific than the
      // current location pattern), we skip reporting here.
      // Example: 'UserModel' (len 13) inside 'entities' (pattern {{name}}, len 8).
      // 'UserModel' is a better match for 'Model' than 'Entity'. Let Location lint handle it.

      // But if 'Login' (len 5) inside 'usecases' (pattern {{name}}, len 8), it matches both.
      // We should NOT skip here, because it is ambiguous.

      final bestMatch = _sortedPatterns.firstWhereOrNull(
            (p) => NamingUtils.validateName(name: className, template: p.pattern),
      );

      if (bestMatch != null && bestMatch.component != actualComponent) {
        // Only skip if the best guess is strictly "better" (e.g. more specific) or equal
        // AND does not also match the current component pattern.
        final matchesCurrent = NamingUtils.validateName(name: className, template: rule.pattern);

        // If it matches current pattern, we enforce current rules (anti-patterns etc)
        if (!matchesCurrent) {
          return;
        }
      }

      // --- Anti-Pattern Check ---
      if (rule.antipattern != null && rule.antipattern!.isNotEmpty) {
        if (NamingUtils.validateName(name: className, template: rule.antipattern!)) {
          reporter.atToken(
            node.name,
            _antiPatternCode,
            arguments: [className, actualComponent.label],
          );
          return;
        }
      }

      // --- Pattern Check ---
      if (!NamingUtils.validateName(name: className, template: rule.pattern)) {
        reporter.atToken(
          node.name,
          _patternCode,
          arguments: [className, rule.pattern, actualComponent.label],
        );
      }
    });
  }

  static List<_ComponentPattern> _createSortedPatterns(List<NamingRule> rules) {
    final patterns =
    rules
        .expand((rule) {
      return rule.on.map((componentId) {
        final component = ArchComponent.fromId(componentId);
        return component != ArchComponent.unknown
            ? _ComponentPattern(pattern: rule.pattern, component: component)
            : null;
      });
    })
        .whereNotNull()
        .toList()
      ..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));
    return patterns;
  }
}

class _ComponentPattern {
  final String pattern;
  final ArchComponent component;

  const _ComponentPattern({required this.pattern, required this.component});
}