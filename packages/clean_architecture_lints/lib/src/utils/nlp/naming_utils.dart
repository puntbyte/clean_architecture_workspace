// lib/src/utils/nlp/naming_utils.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';

/// A utility class for handling syntactic (string-based) naming conventions.
class NamingUtils {
  const NamingUtils._();

  /// A cache for compiled regular expressions to avoid repeated compilation.
  static final Map<String, RegExp> _expressionCache = {};

  static String getExpectedUseCaseClassName(String methodName, ArchitectureConfig config) {
    final pascal = methodName.toPascalCase();
    final rule = config.namingConventions.getRuleFor(ArchComponent.usecase);
    if (rule == null) return pascal;
    // Simple replacement, assumes {{name}} exists in pattern
    return rule.pattern.replaceAll('{{name}}', pascal);
  }

  /// Validates a name against a configured template string using a cached regex.
  static bool validateName({required String name, required String template}) {
    final regex = _expressionCache.putIfAbsent(template, () => _buildRegexForTemplate(template));
    return regex.hasMatch(name);
  }

  /// Builds a regular expression from a template string with placeholders.
  /// This implementation assumes the user-provided parts of the template are valid regex.
  static RegExp _buildRegexForTemplate(String template) {
    const pascalToken = '([A-Z][a-zA-Z0-9]*)';
    const nonGreedyPascalToken = '([A-Z][a-zA-Z0-9]*?)';

    // FIX: Do not escape the template. Replace placeholders directly.
    // This allows users to include regex operators like `|` and `()` in their patterns.
    final pattern = template
        .replaceAll('{{name}}', pascalToken)
        .replaceAll('{{kind}}', nonGreedyPascalToken);

    return RegExp('^$pattern\$');
  }
}
