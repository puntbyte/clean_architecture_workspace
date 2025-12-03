import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';

class FileResolver {
  final ArchitectureConfig config;

  const FileResolver(this.config);

  /// Returns the [ComponentConfig] that matches the given [filePath].
  ///
  /// If multiple components match, it returns the one with the
  /// **most specific** (longest) path pattern.
  ComponentConfig? resolve(String filePath) {
    ComponentConfig? bestMatch;
    var bestMatchLength = -1;

    for (final component in config.components) {
      if (component.paths.isEmpty) continue;

      for (final path in component.paths) {
        if (PathMatcher.matches(filePath, path)) {
          // Heuristic: The longer the config path, the more specific it is.
          // 'domain/usecases' (len: 15) > 'domain' (len: 6)
          // 'features/{{name}}/data' (len: ~20) > 'features' (len: 8)

          if (path.length > bestMatchLength) {
            bestMatchLength = path.length;
            bestMatch = component;
          }
        }
      }
    }

    return bestMatch;
  }
}
