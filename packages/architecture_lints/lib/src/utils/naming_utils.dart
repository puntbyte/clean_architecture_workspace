// lib/src/utils/naming_utils.dart

import 'package:architecture_lints/src/configuration/config_keys.dart';

class NamingUtils {
  const NamingUtils._();

  static final Map<String, RegExp> _expressionCache = {};

  /// Checks if [name] matches the [template] (e.g. '{{name}}Repository').
  static bool validate({required String name, required String template}) {
    final regex = _expressionCache.putIfAbsent(
      template,
      () => _buildRegexForTemplate(template),
    );
    return regex.hasMatch(name);
  }

  static RegExp _buildRegexForTemplate(String template) {
    // {{name}} = Strict PascalCase (Must start with Uppercase, alphanumeric rest)
    const pascalToken = '([A-Z][a-zA-Z0-9]*)';

    // {{affix}} = Non-greedy anything (for prefixes/suffixes like 'Impl' or 'Default')
    const affixToken = '(.*?)';

    // Escape special regex characters that might appear in the template (except our placeholders)
    // We treat the template as a literal structure except for {{...}}
    final pattern = template
        .replaceAll(ConfigKeys.placeholder.name, pascalToken)
        .replaceAll(ConfigKeys.placeholder.affix, affixToken);

    // Anchor start and end to ensure exact match
    return RegExp('^$pattern\$');
  }
}
