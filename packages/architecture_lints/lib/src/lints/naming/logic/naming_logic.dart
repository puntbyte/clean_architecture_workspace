import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/constants/regexps.dart';
import 'package:architecture_lints/src/schema/enums/placeholder_token.dart';
// Note: PathMatcher is no longer needed for escaping if we want to support regex syntax

mixin NamingLogic {
  static final Map<String, RegExp> _regexCache = {};

  bool validateName(String className, String pattern) {
    // Optimization for the common case where pattern is just "${name}"
    if (pattern == PlaceholderToken.name.template) {
      return RegExp('^${RegexConstants.pascalCaseGroup}\$').hasMatch(className);
    }
    final regex = _getRegex(pattern);
    return regex.hasMatch(className);
  }

  String? extractCoreNameFromPattern(String className, String pattern) {
    final regex = _getRegex(pattern);
    final match = regex.firstMatch(className);
    if (match != null && match.groupCount >= 1) return match.group(1);
    return null;
  }

  RegExp _getRegex(String pattern) => _regexCache.putIfAbsent(pattern, () => _buildRegex(pattern));

  RegExp _buildRegex(String pattern) {
    // FIX: Do NOT escape the input pattern.
    // We want to support Regex syntax like '(Bloc|Cubit)' in the config.
    var regexStr = pattern;

    // Replace ${name} -> ([A-Z][a-zA-Z0-9]*)
    // We use literal replacement since the input is a string.
    regexStr = regexStr.replaceAll(
      PlaceholderToken.name.template,
      RegexConstants.pascalCaseGroup,
    );

    // Replace ${affix} -> .*
    regexStr = regexStr.replaceAll(PlaceholderToken.affix.template, RegexConstants.wildcard);

    return RegExp('^$regexStr\$');
  }

  String generateExample(String pattern) {
    return pattern
        .replaceAll(PlaceholderToken.name.template, 'Login')
        .replaceAll(PlaceholderToken.affix.template, 'My')
        // Clean up regex artifacts for display if present
        .replaceAll(RegExp(r'[\(\)\|]'), '') // Remove ( ) |
        .replaceAll(r'\', '') // Remove escapes
        .replaceAll('?', '') // Remove quantifiers
        .replaceAll('^', '') // Remove anchors
        .replaceAll(r'$', '');
  }
}
