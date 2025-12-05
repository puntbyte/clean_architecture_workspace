mixin NamingLogic {
  static const String _placeholderName = '{{name}}';
  static const String _placeholderAffix = '{{affix}}';
  static const String _regexPascalCaseGroup = '([A-Z][a-zA-Z0-9]*)';
  static const String _regexWildcard = '.*';

  /// Caches compiled regexes globally.
  /// Static allows the Rules to be 'const' and improves performance.
  static final Map<String, RegExp> _regexCache = {};

  bool validateName(String className, String pattern) {
    // Optimization: Direct equality check for simple patterns
    if (pattern == _placeholderName) {
      // Just check if it is PascalCase
      return RegExp('^$_regexPascalCaseGroup\$').hasMatch(className);
    }

    final regex = _regexCache.putIfAbsent(pattern, () => _buildRegex(pattern));
    return regex.hasMatch(className);
  }

  RegExp _buildRegex(String pattern) {
    var escaped = RegExp.escape(pattern);

    // Un-escape the specific placeholders
    escaped = escaped
        .replaceAll(RegExp.escape(_placeholderName), _regexPascalCaseGroup)
        .replaceAll(RegExp.escape(_placeholderAffix), _regexWildcard);

    return RegExp('^$escaped\$');
  }

  String generateExample(String pattern) {
    return pattern
        .replaceAll('{{name}}', 'Login')
        .replaceAll('{{affix}}', 'My');
  }
}
