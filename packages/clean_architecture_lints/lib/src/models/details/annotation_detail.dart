// lib/src/models/details/annotation_detail.dart

part of '../configs/annotations_config.dart';

/// Represents the details of a single annotation.
class AnnotationDetail {
  final String name;
  final String? import;

  const AnnotationDetail({
    required this.name,
    this.import,
  });

  static AnnotationDetail? tryFromMap(Map<String, dynamic> map) {
    var name = map.asString(ConfigKey.rule.name);

    // If name is missing in the map, check if it was passed via parent expansion logic
    // (This method usually takes a map representing ONE detail)
    if (name.isEmpty) return null;

    // Strip '@' if present
    if (name.startsWith('@')) {
      name = name.substring(1);
    }

    return AnnotationDetail(
      name: name,
      import: map.asStringOrNull(ConfigKey.rule.import),
    );
  }
}
