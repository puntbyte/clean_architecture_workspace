// lib/src/core/resolver/file_resolver.dart
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';

class FileResolver {
  final ArchitectureConfig config;

  const FileResolver(this.config);

  /// Returns the [ComponentConfig] that matches the given [filePath].
  ComponentConfig? resolve(String filePath) {
    ComponentConfig? bestMatch;

    // We track two metrics to determine the "best" match:
    // 1. Match Start Index: The match that starts later in the string is "deeper".
    // 2. Match Length: If two matches start at the same place, the longer one is specific.
    var bestMatchIndex = -1;
    var bestMatchLength = -1;

    final normalizedFile = filePath.replaceAll(r'\', '/');

    for (final component in config.components) {
      if (component.paths.isEmpty) continue;

      for (final path in component.paths) {
        final matchIndex = PathMatcher.getMatchIndex(normalizedFile, path);

        if (matchIndex != -1) {
          // Logic:
          // 1. Priority to the match that appears LATER in the path (Deeper folder)
          if (matchIndex > bestMatchIndex) {
            bestMatchIndex = matchIndex;
            bestMatchLength = path.length;
            bestMatch = component;
          }
          // 2. If they start at the same spot (rare with simple containment, but possible with globbing),
          // prefer the longer pattern (More specific)
          else if (matchIndex == bestMatchIndex) {
            if (path.length > bestMatchLength) {
              bestMatchLength = path.length;
              bestMatch = component;
            }
          }
        }
      }
    }

    return bestMatch;
  }
}
