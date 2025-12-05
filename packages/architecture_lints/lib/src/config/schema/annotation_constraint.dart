// lib/src/config/constants/annotation_constraint.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class AnnotationConstraint {
  /// The class name of the annotation (e.g. 'Injectable')
  final List<String> types;

  /// Strict import URI (e.g. 'package:injectable/injectable.dart')
  final String? import;

  const AnnotationConstraint({
    this.types = const [],
    this.import,
  });

  factory AnnotationConstraint.fromMap(Map<dynamic, dynamic> map) {
    return AnnotationConstraint(
      types: map.getStringList(ConfigKeys.annotation.type),
      import: map.tryGetString(ConfigKeys.annotation.import),
    );
  }

  static List<AnnotationConstraint> listFromDynamic(dynamic value) {
    if (value is Map) {
      return [AnnotationConstraint.fromMap(value)];
    }
    if (value is List) {
      return value.whereType<Map>().map(AnnotationConstraint.fromMap).toList();
    }
    return [];
  }
}
