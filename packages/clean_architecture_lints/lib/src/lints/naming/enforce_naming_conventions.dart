// lib/srcs/lints/naming/enforce_naming_conventions.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes follow the syntactic naming conventions (`pattern` and `antipattern`).
class EnforceNamingConventions extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_naming_conventions',
    problemMessage: 'The name `{0}` does not follow the required naming conventions for a {1}.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceNamingConventions({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // Pre-build a list of all known patterns for the mislocation check.
    final allPatterns = _getAllPatterns(config.namingConventions);

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      // Determine the precise component for this class using its location and name.
      final actualComponent = layerResolver.getComponent(filePath, className: className);
      if (actualComponent == ArchComponent.unknown) return;

      // Get the specific naming rule for the component we're analyzing.
      final rule = config.namingConventions.getRuleFor(actualComponent);
      if (rule == null) return;

      // --- Pre-Check for Mislocation ---
      // This prevents this lint from firing on a class that is clearly a "location" problem.
      final bestGuessComponent = _getBestGuessComponent(className, allPatterns);
      if (bestGuessComponent != null && bestGuessComponent != actualComponent) {
        return; // This is a location problem. Let the location lint handle it.
      }

      // --- Main Naming Logic ---

      // GATE 1: ANTI-PATTERN CHECK
      if (rule.antipattern != null && rule.antipattern!.isNotEmpty) {
        if (NamingUtils.validateName(name: className, template: rule.antipattern!)) {
          reporter.atToken(
            node.name,
            LintCode(
              name: _code.name,
              problemMessage:
                  'The name `$className` uses a forbidden pattern for a ${actualComponent.label}.',
            ),
          );
          return;
        }
      }

      // GATE 2: PATTERN CHECK
      if (!NamingUtils.validateName(name: className, template: rule.pattern)) {
        reporter.atToken(
          node.name,
          LintCode(
            name: _code.name,
            problemMessage:
                'The name `$className` does not match the required `${rule.pattern}` convention '
                    'for a ${actualComponent.label}.',
          ),
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

  /// Finds the best-fit architectural component for a class based on its name.
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
