// lib/src/models/details/annotation_detail.dart

part of '../annotations_config.dart';

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
    if (name.isEmpty) return null;

    // FIX: Automatically strip '@' if the user included it in the config.
    // The Analyzer AST exposes the name without the '@', so we must match that.
    if (name.startsWith('@')) {
      name = name.substring(1);
    }

    return AnnotationDetail(
      name: name,
      import: map.asStringOrNull(ConfigKey.rule.import),
    );
  }
}
