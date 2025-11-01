/// A utility extension on [String] for common case conversions.
extension StringCaseUtils on String {
  /// Converts a string from camelCase or snake_case to PascalCase.
  ///
  /// Examples:
  /// - `getUser` -> `GetUser`
  /// - `get_user` -> `GetUser`
  String toPascalCase() {
    if (isEmpty) return '';
    return this[0].toUpperCase() + substring(1);
  }

  /// Converts a string from PascalCase or camelCase to snake_case.
  ///
  /// Examples:
  /// - `GetUser` -> `get_user`
  /// - `getUser` -> `get_user`
  String toSnakeCase() {
    return replaceAllMapped(
      RegExp('(?<!^)(?=[A-Z])'),
      (match) => '_${match.group(0)}',
    ).toLowerCase();
  }
}
