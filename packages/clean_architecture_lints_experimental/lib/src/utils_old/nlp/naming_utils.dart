// lib/src/utils/nlp/naming_utils.dart

import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/models/configs/architecture_config.dart';
import 'package:architecture_lints/src/utils/extensions/string_extension.dart';

class NamingUtils {
  const NamingUtils._();

  static final Map<String, RegExp> _expressionCache = {};

  static String getExpectedUseCaseClassName(String methodName, ArchitectureConfig config) {
    final pascal = methodName.toPascalCase();
    final rule = config.namingConventions.ruleFor(ArchComponent.usecase);
    if (rule == null) return pascal;
    return rule.pattern.replaceAll('{{name}}', pascal);
  }

  static bool validateName({required String name, required String template}) {
    final regex = _expressionCache.putIfAbsent(template, () => _buildRegexForTemplate(template));
    return regex.hasMatch(name);
  }

  static RegExp _buildRegexForTemplate(String template) {
    // Greedy capture for the main name
    const pascalToken = '([A-Z][a-zA-Z0-9]*)';
    // Non-greedy capture for affixes (prefixes/suffixes)
    const nonGreedyPascalToken = '([A-Z][a-zA-Z0-9]*?)';

    final pattern = template
        .replaceAll('{{name}}', pascalToken)
        .replaceAll('{{affix}}', nonGreedyPascalToken);
    // Anchor start and end to ensure exact match
    return RegExp('^$pattern\$');
  }
}
