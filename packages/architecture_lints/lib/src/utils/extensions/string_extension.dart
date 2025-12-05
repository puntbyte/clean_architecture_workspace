// lib/src/utils/extensions/string_extension.dart

/// A utility extension on [String] for common case conversions, with robust
/// handling for developer-centric acronyms (e.g., DTO, API, Id).
extension StringExtension on String {
  /// Converts a string from various cases (camel, snake, kebab) to PascalCase,
  /// correctly preserving or identifying acronyms.
  ///
  /// Examples:
  /// - `get_user_profile` -> `GetUserProfile`
  /// - `fetchApiData` -> `FetchAPIData`
  /// - `userId` -> `UserID`
  String toPascalCase() {
    if (isEmpty) return '';

    // A robust regex to find word boundaries. It handles snake_case, camelCase,
    // and acronyms by looking for sequences of uppercase letters, or an
    // optional uppercase followed by lowercase letters.
    final regex = RegExp('[A-Z]?[a-z]+|[A-Z]+(?![a-z])|[0-9]+');

    // Normalize different separators to a space for consistent splitting.
    final spaced = replaceAll(RegExp(r'[-_\s]+'), ' ');

    final words = regex.allMatches(spaced).map((m) => m.group(0)!).toList();
    if (words.isEmpty) return '';

    // The first word is always capitalized.
    final firstWord = words.first;
    final buffer = StringBuffer(firstWord[0].toUpperCase() + firstWord.substring(1));

    // Process the rest of the words.
    for (var i = 1; i < words.length; i++) {
      final word = words[i];
      // A key heuristic: if a word is short (like 'Id', 'Api', 'Dto') and was
      // already capitalized, it's likely intended as an acronym.
      if (word.length <= 3 && word[0].toUpperCase() == word[0]) {
        buffer.write(word.toUpperCase());
      } else {
        // Otherwise, apply standard capitalization.
        buffer.write(word[0].toUpperCase() + word.substring(1));
      }
    }

    return buffer.toString();
  }

  /// Converts a string from PascalCase or camelCase to snake_case,
  /// correctly handling acronyms.
  ///
  /// Examples:
  /// - `GetUserProfile` -> `get_user_profile`
  /// - `UserDTO` -> `user_dto`
  /// - `getAPIData` -> `get_api_data`
  String toSnakeCase() {
    if (isEmpty) return '';

    // This regex is already robust for snake_case conversion.
    // It finds boundaries between lowercase and uppercase, and between
    // acronyms and subsequent words.
    return replaceAllMapped(
      RegExp('(?<=[a-z0-9])([A-Z])'),
      (m) => '_${m[1]}',
    ).replaceAllMapped(RegExp('(?<=[A-Z])([A-Z][a-z])'), (m) => '_${m[1]}').toLowerCase();
  }

  /// Splits a PascalCase string into its constituent words, correctly handling acronyms.
  /// Example: "HandleDTO" -> ["Handle", "DTO"]
  List<String> splitPascalCase() {
    if (isEmpty) return [];
    // This regex handles consecutive capital letters (acronyms) as a single word.
    final matches = RegExp('[A-Z][a-z]+|[A-Z]+(?![a-z])|[0-9]+').allMatches(this);
    return matches.map((m) => m.group(0)!).toList();
  }
}
