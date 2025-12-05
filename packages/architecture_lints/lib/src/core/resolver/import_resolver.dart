// lib/src/core/resolver/import_resolver.dart

import 'package:analyzer/dart/ast/ast.dart';

class ImportResolver {
  /// Resolves the absolute file path of an import directive.
  /// Returns null if the import cannot be resolved, points to a dart: lib,
  /// or points to a file that does not exist.
  static String? resolvePath({required ImportDirective node}) {
    // 1. Ignore dart: imports
    final uriString = node.uri.stringValue;
    if (uriString != null && uriString.startsWith('dart:')) {
      return null;
    }

    // 2. Resolve the Library Element
    final libraryImport = node.libraryImport;
    if (libraryImport == null) return null;

    final importedLibrary = libraryImport.importedLibrary;
    if (importedLibrary == null) return null;

    // 3. Get the Source from the first fragment
    final source = importedLibrary.firstFragment.source;

    // 4. CHECK EXISTENCE:
    // The Analyzer might create a Source object for a missing file
    // (to report an error). We return null in this case to avoid
    // linting against non-existent files (e.g. ungenerated code).
    if (!source.exists()) {
      return null;
    }

    // 5. Check Scheme (file: or package:)
    final uri = source.uri;
    if (!uri.isScheme('file') && !uri.isScheme('package')) {
      return null;
    }

    return source.fullName;
  }
}
