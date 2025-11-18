// lib/src/utils/naming_utils.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';

/// A utility class for handling syntactic (string-based) naming conventions.
class NamingUtils {
  const NamingUtils._();

  /// A cache for compiled regular expressions to avoid repeated compilation.
  static final Map<String, RegExp> _expressionCache = {};

  /// Converts a repository method name into an expected UseCase class name.
  static String getExpectedUseCaseClassName(String methodName, ArchitectureConfig config) {
    final pascal = methodName.toPascalCase();
    final rule = config.namingConventions.getRuleFor(ArchComponent.usecase);
    // A rule should always exist, but we check for safety.
    if (rule == null) return pascal;
    return rule.pattern.replaceAll('{{name}}', pascal);
  }

  /// Validates a name against a configured template string using a cached regex.
  static bool validateName({required String name, required String template}) {
    // Retrieve the compiled regex from cache or build and cache it.
    final regex = _expressionCache.putIfAbsent(template, () => _buildRegexForTemplate(template));
    return regex.hasMatch(name);
  }

  /// Builds a regular expression from a template string with placeholders.
  static RegExp _buildRegexForTemplate(String template) {
    // Define the regex representation for our placeholders.
    // `kind` is non-greedy (`*?`) to correctly handle `{{kind}}{{name}}` patterns,
    // where it should match the shortest possible prefix (e.g., "Default").
    const pascalToken = '([A-Z][a-zA-Z0-9]*)';
    const nonGreedyPascalToken = '([A-Z][a-zA-Z0-9]*?)';

    // 1. Escape all special regex characters in the original template.
    var pattern = RegExp.escape(template);

    // 2. Un-escape our placeholders and replace them with their regex tokens.
    pattern = pattern
        .replaceAll(RegExp.escape('{{kind}}'), nonGreedyPascalToken)
        .replaceAll(RegExp.escape('{{name}}'), pascalToken);

    // 3. Anchor the pattern to ensure it matches the entire string.
    return RegExp('^$pattern\$');
  }
}
