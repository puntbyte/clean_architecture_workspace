import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class TypeSafetyConstraint {
  /// 'return' or 'parameter'
  final String kind;

  /// Regex pattern for parameter name (only if kind == 'parameter')
  final String? identifier;

  /// References to 'types' definitions (e.g. 'result.wrapper')
  final List<String> definitions;

  /// Raw type names (e.g. 'int', 'String')
  final List<String> types;

  /// Architectural component reference (e.g. 'model')
  final String? component;

  const TypeSafetyConstraint({
    required this.kind,
    this.identifier,
    this.definitions = const [],
    this.types = const [],
    this.component,
  });

  factory TypeSafetyConstraint.fromMap(Map<dynamic, dynamic> map) {
    return TypeSafetyConstraint(
      kind: map.getString(ConfigKeys.typeSafety.kind, fallback: 'return'),
      identifier: map.tryGetString(ConfigKeys.typeSafety.identifier),
      definitions: map.getStringList(ConfigKeys.typeSafety.definition),
      types: map.getStringList(ConfigKeys.typeSafety.type),
      component: map.tryGetString(ConfigKeys.typeSafety.component),
    );
  }

  // Helper to allow single objects or lists in YAML
  static List<TypeSafetyConstraint> listFromDynamic(dynamic value) {
    if (value is Map) {
      return [TypeSafetyConstraint.fromMap(value)];
    }
    if (value is List) {
      return value.map((e) {
        if (e is Map) return TypeSafetyConstraint.fromMap(e);
        return null;
      }).whereType<TypeSafetyConstraint>().toList();
    }
    return [];
  }
}
