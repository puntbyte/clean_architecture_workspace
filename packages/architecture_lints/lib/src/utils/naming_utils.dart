import 'package:architecture_lints/src/config/constants/config_keys.dart';

class NamingUtils {
  const NamingUtils._();

  // Regex Patterns defined locally
  static const String _regexPascalCaseGroup = '([A-Z][a-zA-Z0-9]*)';
  static const String _regexWildcard = '.*';

  static final Map<String, RegExp> _expressionCache = {};

  static bool validateName({required String name, required String template}) {
    final regex = _expressionCache.putIfAbsent(template, () => _buildRegexForTemplate(template));
    return regex.hasMatch(name);
  }

  static RegExp _buildRegexForTemplate(String template) {
    var pattern = template;

    // Replace {{name}} with PascalCase capture
    pattern = pattern.replaceAll(ConfigKeys.placeholder.name, _regexPascalCaseGroup);

    // Replace {{affix}} with Wildcard
    pattern = pattern.replaceAll(ConfigKeys.placeholder.affix, _regexWildcard);

    return RegExp('^$pattern\$');
  }
}
