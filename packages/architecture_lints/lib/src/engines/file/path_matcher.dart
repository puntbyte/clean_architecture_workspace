// lib/src/engines/file/path_matcher.dart

import 'package:architecture_lints/src/schema/constants/regexps.dart';
import 'package:architecture_lints/src/schema/enums/placeholder_token.dart';

class PathMatcher {
  /// Returns the start index of the match in [filePath], or -1 if no match.
  static int getMatchIndex(String filePath, String configPath) {
    final normalizedFile = filePath.replaceAll(r'\', '/');
    final normalizedConfig = configPath.replaceAll(r'\', '/');

    final nameTemplate = PlaceholderToken.name.template; // "{{name}}"

    // 1. Handle {{name}} wildcard
    if (normalizedConfig.contains(nameTemplate)) {
      final escapedConfig = RegexConstants.escape(normalizedConfig);
      final escapedPlaceholder = RegexConstants.escape(nameTemplate);

      // Use centralized pathSegment pattern
      final pattern = escapedConfig.replaceAll(escapedPlaceholder, RegexConstants.pathSegment);

      final regex = RegExp(pattern);
      final match = regex.firstMatch(normalizedFile);
      return match?.start ?? -1;
    }

    // 2. Handle standard Glob wildcard (*)
    if (normalizedConfig.contains('*')) {
      // Use centralized wildcard
      final pattern = RegexConstants.escape(normalizedConfig)
          .replaceAll(r'\*', RegexConstants.wildcard);
      // Note: wildcard in paths usually means "anything", not non-greedy

      final regex = RegExp(pattern);
      final match = regex.firstMatch(normalizedFile);
      return match?.start ?? -1;
    }

    // 3. Robust Containment Check
    // We check for folder boundaries to avoid partial name matches (e.g. 'port' matching 'support')

    // Check '/configPath/' (Middle)
    final index = normalizedFile.indexOf('/$normalizedConfig/');
    if (index != -1) return index + 1;

    // Check '/configPath' (End)
    if (normalizedFile.endsWith('/$normalizedConfig')) {
      return normalizedFile.length - normalizedConfig.length;
    }

    // Check 'configPath/' (Start - unlikely for absolute paths but good for relative)
    if (normalizedFile.startsWith('$normalizedConfig/')) {
      return 0;
    }

    // Fallback: Exact match
    if (normalizedFile == normalizedConfig) return 0;

    return -1;
  }

  static bool matches(String filePath, String configPath) {
    if (configPath.startsWith('*') && !configPath.contains('/')) {
      final extension = configPath.substring(1);
      return filePath.endsWith(extension);
    }
    return getMatchIndex(filePath, configPath) != -1;
  }
}
