// lib/src/utils/extensions/string_extension.dart

/// A utility extension on [String] for common case conversions.
extension StringExtension on String {
  // A regular expression to find word boundaries in camelCase or snake_case.
  static final RegExp _wordRegExp = RegExp('(_)?([A-Z][a-z]*|[a-z]+|[0-9]+)');

  /// Converts a string from camelCase, snake_case, or kebab-case to PascalCase.
  ///
  /// Examples:
  /// - `getUser` -> `GetUser`
  /// - `get_all_users` -> `GetAllUsers`
  /// - `my-api-service` -> `MyApiService`
  String toPascalCase() {
    if (isEmpty) return '';

    return _wordRegExp.allMatches(this).map((match) {
      final word = match.group(2)!;
      return word[0].toUpperCase() + word.substring(1);
    }).join();
  }

  /// Converts a string from PascalCase or camelCase to snake_case.
  ///
  /// Examples:
  /// - `GetUser` -> `get_user`
  /// - `myVariable` -> `my_variable`
  String toSnakeCase() {
    if (isEmpty) return '';

    return replaceAllMapped(RegExp('(?<!^)(?=[A-Z])'), (match) => '_${match.group(0)}')
        .toLowerCase();
  }
}
