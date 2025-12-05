import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MisplacedComponentRule extends ArchitectureLintRule with NamingLogic {
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
    ComponentConfig? component,
  }) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;

      // 1. Quick Exit: If the class ALREADY matches the current component's pattern, it is fine.
      // This prevents false positives if multiple components share similar patterns.
      if (component != null && component.patterns.isNotEmpty) {
        for (final pattern in component.patterns) {
          if (validateName(className, pattern)) {
            return; // Correctly placed
          }
        }
      }

      // 2. Search for a better home
      ComponentConfig? bestMatch;
      var bestMatchSpecificity = -1;

      for (final otherComponent in config.components) {
        // Skip current component (already checked or null)
        if (component != null && otherComponent.id == component.id) continue;

        // Skip components that don't have file paths (e.g. abstract definitions) or patterns
        if (otherComponent.paths.isEmpty || otherComponent.patterns.isEmpty) continue;

        for (final pattern in otherComponent.patterns) {
          if (validateName(className, pattern)) {
            // Heuristic: The longer the pattern string, the more specific it usually is.
            // Example: "{{name}}Repository" (Length ~18) is better than "{{name}}" (Length 8).
            // We want to avoid flagging "UserEntity" as a generic "Widget" just because Widget allows "{{name}}".
            if (pattern.length > bestMatchSpecificity) {
              bestMatchSpecificity = pattern.length;
              bestMatch = otherComponent;
            }
          }
        }
      }

      if (bestMatch != null) {
        final pathHint = bestMatch.paths.join('" or "');

        reporter.atToken(
          node.name,
          _code,
          arguments: [
            className,
            bestMatch.displayName, // Use the getter directly
            pathHint,
          ],
        );
      }
    });
  }
}
