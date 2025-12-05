import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/config/schema/type_definition.dart';
import 'package:meta/meta.dart';

@immutable
class TypeContext {
  final String key; // e.g. 'usecase.unary'
  final TypeDefinition definition;

  const TypeContext({required this.key, required this.definition});

  /// Checks if the given [dartType] matches this definition.
  /// Checks both the Name and the Import URI (if configured).
  bool matches(DartType dartType) {
    // 1. Check Canonical Element
    if (_matchesElement(dartType.element)) return true;

    // 2. Check Alias (typedef)
    if (dartType.alias != null) {
      if (_matchesElement(dartType.alias!.element)) return true;
    }

    return false;
  }

  bool _matchesElement(Element? element) {
    if (element == null) return false;

    // Check Name
    if (element.name != definition.type) return false;

    // Check Import (if defined)
    if (definition.import != null) {
      final lib = element.library;
      if (lib == null) return false;

      // Analyzer 8.x compatible source access
      final uri = lib.firstFragment.source.uri.toString();
      return uri == definition.import;
    }

    return true;
  }
}
