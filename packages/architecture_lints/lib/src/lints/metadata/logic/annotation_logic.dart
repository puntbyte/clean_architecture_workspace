import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/annotation_constraint.dart';

mixin AnnotationLogic {
  bool matchesConstraint(Annotation node, AnnotationConstraint constraint) {
    // 1. Check Name (Normalized & Case-Insensitive)
    final annotationName = _getAnnotationName(node);

    final hasNameMatch = constraint.types.any(
      (type) => _normalizeName(type) == _normalizeName(annotationName),
    );

    if (!hasNameMatch) return false;

    // 2. Check Import (Optional)
    if (constraint.import == null) return true;

    // 3. Strict Import Check
    final expectedImport = constraint.import!;

    // A) Try Resolved Element URI
    final resolvedUri = _extractSourceUriFromElement(node.element);
    if (resolvedUri != null && _matchesImport(resolvedUri, expectedImport)) {
      return true;
    }

    // B) Fallback: Scan file imports
    return _scanFileImports(node, expectedImport);
  }

  /// Checks if an [importNode] matches a [constraint] based on URI.
  bool matchesImportConstraint(ImportDirective importNode, AnnotationConstraint constraint) {
    // If the constraint doesn't specify a strict import, we can't ban a file import
    // just based on a class name (we don't know what's in the file yet).
    if (constraint.import == null) return false;

    final uriString = importNode.uri.stringValue;
    if (uriString == null) return false;

    return _matchesImport(uriString, constraint.import!);
  }

  String _getAnnotationName(Annotation node) {
    final id = node.name;
    if (id is PrefixedIdentifier) {
      return id.identifier.name;
    }
    return id.name;
  }

  /// Normalizes the name by removing '@' and converting to LowerCase.
  String _normalizeName(String name) {
    var n = name;
    if (n.startsWith('@')) n = n.substring(1);
    // CRITICAL FIX: Make it case-insensitive
    return n.toLowerCase();
  }

  String? _extractSourceUriFromElement(Element? element) {
    if (element == null) return null;
    final lib = element.library;
    if (lib != null) {
      return lib.firstFragment.source.uri.toString();
    }
    return null;
  }

  bool _scanFileImports(Annotation node, String expectedImport) {
    final unit = node.thisOrAncestorOfType<CompilationUnit>();
    if (unit == null) return false;

    return unit.directives.whereType<ImportDirective>().any((imp) {
      final uriString = imp.uri.stringValue;
      if (uriString == null) return false;
      return _matchesImport(uriString, expectedImport);
    });
  }

  bool _matchesImport(String actual, String expected) {
    if (actual == expected) return true;
    if (actual.startsWith(expected)) return true;

    // Handle 'package:injectable/injectable.dart' matching 'package:injectable'
    // or relative imports resolving to the same thing (simplified check)
    if (expected.startsWith('package:') && actual.endsWith(expected.split('/').last)) {
      return true;
    }

    return false;
  }

  String describeConstraint(AnnotationConstraint c) {
    return c.types.join(' or ');
  }
}
