import 'package:architecture_lints/src/utils/token_syntax.dart';

class RegexConstants {
  const RegexConstants._();

  // --- Raw Patterns (Strings) ---

  /// Matches a PascalCase word (Starts with Uppercase, followed by alphanumeric).
  /// Used for identifying class names.
  static const String pascalCaseGroup = '([A-Z][a-zA-Z0-9]*)';

  /// Matches anything (Non-greedy).
  /// Used for {{affix}} replacement.
  static const String wildcard = '.*?';

  /// Matches any character except a forward slash.
  /// Used for path segment matching.
  static const String pathSegment = '[^/]+';

  // --- Compiled Regexes (Reusable) ---

  /// Finds `{{...}}` blocks for interpolation.
  /// Matches `{{` followed by any character except `}` followed by `}}`.
  //static final RegExp interpolation = RegExp(r'\{\{([^}]+)\}\}');

  static RegExp get interpolation {
    final open = RegExp.escape(TokenSyntax.open);
    final close = RegExp.escape(TokenSyntax.close);
    // Captures content between {{ and }}
    return RegExp('$open([^$close]+)$close');
  }

  /// Finds the boundary between lower and uppercase letters.
  /// Used for snake_case conversion (e.g. "u|Ser").
  static final RegExp snakeCaseBoundary = RegExp('([a-z])([A-Z])');

  /// Characters that must be escaped when converting a string literal to a Regex.
  static final RegExp specialChars = RegExp(r'[.*+?^${}()|[\]\\]');

  // --- Helpers ---

  /// Escapes special regex characters in a string.
  static String escape(String text) {
    return text.replaceAllMapped(specialChars, (match) => '\\${match.group(0)}');
  }
}
