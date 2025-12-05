import 'package:analyzer/dart/ast/ast.dart'; // Required for ClassDeclaration
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart'; // Mixin
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart'; // Mixin
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MisplacedComponentRule extends ArchitectureLintRule with NamingLogic, InheritanceLogic {
  static const _code = LintCode(
    name: 'arch_location',
    problemMessage: 'The class "{0}" appears to be a {1}, but it is located in the wrong layer.',
    correctionMessage: 'Move this file to the "{2}" directory.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const MisplacedComponentRule() : super(code: _code);

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component,
  }) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      // 1. Current Context Check
      // If the class ALREADY matches the current component's pattern, it is correctly placed.
      // This prevents flagging a file just because it *also* looks like something else.
      if (component != null && component.patterns.isNotEmpty) {
        for (final pattern in component.patterns) {
          if (validateName(className, pattern)) {
            return; // Correctly placed
          }
        }
      }

      // 2. Strong Signal: Inheritance
      // If the class extends a known architectural type, that trumps naming.
      final inheritanceId = findComponentIdByInheritance(node, config, fileResolver);
      if (inheritanceId != null) {
        // If we found a specific ID via inheritance, and it doesn't match the current component location
        if (component?.id != inheritanceId) {
          try {
            final realComponent = config.components.firstWhere((c) => c.id == inheritanceId);
            _report(reporter, node, className, realComponent);
            return; // Stop here, inheritance is definitive
          } catch (_) {}
        }
      }

      // 3. Weak Signal: Naming Specificity
      // We scan other components to see if the name strictly matches their pattern.
      ComponentConfig? bestMatch;
      var bestMatchScore = 0;

      for (final otherComponent in config.components) {
        // Skip current component (already checked or null)
        if (component != null && otherComponent.id == component.id) continue;

        // Skip components with no paths (abstract definitions) or no patterns
        if (otherComponent.paths.isEmpty || otherComponent.patterns.isEmpty) continue;

        for (final pattern in otherComponent.patterns) {
          if (validateName(className, pattern)) {
            // Calculate Score: Count literal characters (excluding placeholders)
            // '{{name}}Repository' -> Score 10 ('Repository')
            // '{{name}}'           -> Score 0
            final score = _calculateSpecificity(pattern);

            // We only suggest moving if the match is SPECIFIC.
            // Generics (Score 0) are ignored to avoid false positives on common names like "User".
            if (score > 0) {
              if (score > bestMatchScore) {
                bestMatchScore = score;
                bestMatch = otherComponent;
              }
            }
          }
        }
      }

      if (bestMatch != null) {
        _report(reporter, node, className, bestMatch);
      }
    });
  }

  int _calculateSpecificity(String pattern) {
    // Strip placeholders to measure the "uniqueness" of the pattern
    return pattern.replaceAll('{{name}}', '').replaceAll('{{affix}}', '').length;
  }

  void _report(
    DiagnosticReporter reporter,
    ClassDeclaration node,
    String className,
    ComponentConfig targetComponent,
  ) {
    reporter.atToken(
      node.name,
      _code,
      arguments: [
        className,
        targetComponent.displayName,
        targetComponent.paths.join('" or "'),
      ],
    );
  }
}
