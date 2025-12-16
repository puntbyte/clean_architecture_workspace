class TokenSyntax {
  const TokenSyntax._(); // Private constructor to prevent instantiation

  static const String open = '{{';
  static const String close = '}}';
  static const int _openLen = open.length;
  static const int _closeLen = close.length;

  /// Wraps a value in delimiters.
  /// Example: 'name' -> '{{name}}'
  static String wrap(String value) => '$open$value$close';

  /// Removes the outer delimiters if they exist.
  /// Example: '{{name}}' -> 'name'
  /// Example: 'name' -> 'name' (Unchanged)
  static String unwrap(String value) {
    if (value.length >= (_openLen + _closeLen) &&
        value.startsWith(open) &&
        value.endsWith(close)) {
      return value.substring(_openLen, value.length - _closeLen);
    }
    return value;
  }

  /// Helper to check if a string is a token.
  static bool isWrapped(String value) {
    return value.startsWith(open) && value.endsWith(close);
  }
}
