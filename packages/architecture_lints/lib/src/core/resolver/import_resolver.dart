import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as p;

class ImportResolver {
  /// Resolves the absolute path of an import directive.
  /// Returns null if it's a 'dart:' import or cannot be resolved.
  static String? resolvePath({
    required ImportDirective node,
    required String currentFilePath,
    required String packageName,
  }) {
    final uri = node.uri.stringValue;
    if (uri == null) return null;

    // 1. Ignore Dart SDK imports (handled by a different check usually)
    if (uri.startsWith('dart:')) return null;

    // 2. Handle 'package:' imports
    if (uri.startsWith('package:')) {
      // Check if it matches the current project's package name
      if (uri.startsWith('package:$packageName/')) {
        // Remove 'package:my_app/' and prepend 'lib/'
        final relativePath = uri.replaceFirst('package:$packageName/', 'lib/');

        // We need an absolute path to match our FileResolver logic
        // We assume the project root is reachable.
        // A robust way involves looking at the context, but for now:
        final projectRoot = _findProjectRoot(currentFilePath);
        if (projectRoot != null) {
          return p.normalize(p.join(projectRoot, relativePath));
        }
      }
      // If it's a 3rd party package, we ignore it for now (or handle 'external' checks later)
      return null;
    }

    // 3. Handle Relative imports (../domain/entity.dart)
    final currentDir = p.dirname(currentFilePath);
    final absolutePath = p.normalize(p.join(currentDir, uri));
    return absolutePath;
  }

  /// Helper to find the root based on 'lib' folder location
  static String? _findProjectRoot(String filePath) {
    final parts = p.split(filePath);
    final libIndex = parts.indexOf('lib');
    if (libIndex == -1) return null;

    // Return path up to (but not including) 'lib'
    return p.joinAll(parts.sublist(0, libIndex));
  }
}
