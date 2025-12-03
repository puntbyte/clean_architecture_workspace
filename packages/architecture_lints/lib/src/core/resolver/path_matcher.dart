class PathMatcher {
  /// Checks if [filePath] matches the [configPath].
  ///
  /// [configPath] can be a simple string (e.g., 'domain/usecases')
  /// or contain wildcards (e.g., 'features/{{name}}/data').
  static bool matches(String filePath, String configPath) {
    // 1. Normalize separators to forward slashes for consistency
    final normalizedFile = filePath.replaceAll(r'\', '/');
    final normalizedConfig = configPath.replaceAll(r'\', '/');

    // 2. Handle {{name}} wildcard
    // Matches "features/{{name}}/data" against "features/auth/data"
    if (normalizedConfig.contains('{{name}}')) {
      // Escape special regex characters in the config path, except {{name}}
      final pattern = _escapeRegex(normalizedConfig)
          .replaceAll(r'\{\{name\}\}', '[^/]+'); // {{name}} becomes "anything except slash"

      final regex = RegExp(pattern);
      return regex.hasMatch(normalizedFile);
    }

    // 3. Handle standard Glob wildcard (*)
    if (normalizedConfig.contains('*')) {
      final pattern = _escapeRegex(normalizedConfig)
          .replaceAll(r'\*', '.*'); // * becomes "anything"

      final regex = RegExp(pattern);
      return regex.hasMatch(normalizedFile);
    }

    // 4. Basic containment check (for exact paths like 'core/utils')
    // We check if the file path *contains* the config path segments.
    return normalizedFile.contains(normalizedConfig);
  }

  static String _escapeRegex(String text) {
    return text.replaceAllMapped(
        RegExp(r'[.*+?^${}()|[\]\\]'),
            (match) => '\\${match.group(0)}'
    );
  }
}
