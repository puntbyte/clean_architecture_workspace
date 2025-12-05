// lib/src/core/resolver/path_matcher.dart

class PathMatcher {
  /// Returns the start index of the match in [filePath], or -1 if no match.
  static int getMatchIndex(String filePath, String configPath) {
    final normalizedFile = filePath.replaceAll(r'\', '/');
    final normalizedConfig = configPath.replaceAll(r'\', '/');

    // 1. Handle {{name}} wildcard
    if (normalizedConfig.contains('{{name}}')) {
      final pattern = escapeRegex(normalizedConfig).replaceAll(r'\{\{name\}\}', '[^/]+');
      final regex = RegExp(pattern);
      final match = regex.firstMatch(normalizedFile);
      return match?.start ?? -1;
    }

    // 2. Handle standard Glob wildcard (*)
    if (normalizedConfig.contains('*')) {
      final pattern = escapeRegex(normalizedConfig).replaceAll(r'\*', '.*');
      final regex = RegExp(pattern);
      final match = regex.firstMatch(normalizedFile);
      return match?.start ?? -1;
    }

    // 3. Robust Containment Check
    // We check for folder boundaries to avoid partial name matches (e.g. 'port' matching 'support')

    // Check '/configPath/' (Middle)
    final index = normalizedFile.indexOf('/$normalizedConfig/');
    if (index != -1) return index + 1; // +1 to skip the leading slash

    // Check '/configPath' (End)
    if (normalizedFile.endsWith('/$normalizedConfig')) {
      return normalizedFile.length - normalizedConfig.length;
    }

    // Check 'configPath/' (Start)
    if (normalizedFile.startsWith('$normalizedConfig/')) {
      return 0;
    }

    // Fallback: Exact match
    if (normalizedFile == normalizedConfig) return 0;

    return -1;
  }

  static bool matches(String filePath, String configPath) {
    // 1. Handle file extension check specifically for excludes like '*.g.dart'
    if (configPath.startsWith('*') && !configPath.contains('/')) {
      final extension = configPath.substring(1); // remove *
      return filePath.endsWith(extension);
    }

    // 2. Fallback to standard index matching
    return getMatchIndex(filePath, configPath) != -1;
  }

  static String escapeRegex(String text) {
    return text.replaceAllMapped(RegExp(r'[.*+?^${}()|[\]\\]'), (match) => '\\${match.group(0)}');
  }
}
