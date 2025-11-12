// lib/src/analysis/component_resolver.dart


import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/models/component_config.dart';
import 'package:path/path.dart' as p;

/// A query engine for the architectural `components` tree.
///
/// This class traverses the user-defined component hierarchy to resolve the most
/// specific architectural component for a given file path.
class ComponentResolver {
  final ArchitectureConfig _config;

  ComponentResolver(this._config);

  /// Resolves the most specific `ComponentConfig` that matches a file path.
  ///
  /// It performs a depth-first search on the component tree, returning the
  /// deepest node whose `directory` matches a segment in the file path.
  /// Returns `null` if no component matches.
  ComponentConfig? resolveComponent(String path) {
    final segments = _getRelativePathSegments(path);
    if (segments == null) return null;

    // Start the recursive search from the top-level components.
    return _findDeepestMatch(
      pathSegments: segments,
      componentsToSearch: _config.components.values.toList(),
    );
  }

  /// A recursive helper to perform a depth-first search for a matching component.
  ComponentConfig? _findDeepestMatch({
    required List<String> pathSegments,
    required List<ComponentConfig> componentsToSearch,
  }) {
    ComponentConfig? bestMatch;

    for (final component in componentsToSearch) {
      // Check if the current file path is within this component's directory.
      final isMatch = component.directories.any(pathSegments.contains);

      if (isMatch) {
        // This component is a potential match.
        bestMatch = component;

        // Now, search its children to see if a more specific match exists.
        final deeperMatch = _findDeepestMatch(
          pathSegments: pathSegments,
          componentsToSearch: component.subComponents.values.toList(),
        );

        // If a deeper match was found, it is the new best match.
        if (deeperMatch != null) {
          bestMatch = deeperMatch;
        }
      }
    }

    return bestMatch;
  }

  /// Gets the path segments relative to the `lib` directory.
  List<String>? _getRelativePathSegments(String absolutePath) {
    final normalized = p.normalize(absolutePath).replaceAll(r'\', '/');
    final segments = normalized.split('/');
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;
    return segments.sublist(libIndex + 1);
  }
}
