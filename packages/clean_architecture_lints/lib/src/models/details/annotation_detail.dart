// lib/src/models/details/annotation_detail.dart

part of 'package:clean_architecture_lints/src/models/annotations_config.dart';

/// Represents the details of a single annotation (its name and optional import).
/// The name is the annotation class name without the `@` prefix or `()` suffix.
class AnnotationDetail {
  final String name;
  final String? import;

  const AnnotationDetail({
    required this.name,
    this.import,
  });

  /// Creates an instance from a map, returning null if required [name] is empty.
  static AnnotationDetail? tryFromMap(Map<String, dynamic> map) {
    final name = map.asString(ConfigKey.rule.name);
    if (name.isEmpty) return null;

    return AnnotationDetail(
      name: name,
      import: map.asStringOrNull(ConfigKey.rule.import),
    );
  }
}
