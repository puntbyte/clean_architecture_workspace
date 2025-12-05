// lin/src/config/schema/annotation_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/enums/annotation_mode.dart';
import 'package:architecture_lints/src/config/schema/annotation_constraint.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class AnnotationConfig {
  final List<String> onIds;
  final AnnotationMode mode;
  final List<AnnotationConstraint> required;
  final List<AnnotationConstraint> allowed;
  final List<AnnotationConstraint> forbidden;

  const AnnotationConfig({
    required this.onIds,
    required this.required,
    required this.allowed,
    required this.forbidden,
    this.mode = AnnotationMode.implicit,
  });

  factory AnnotationConfig.fromMap(Map<dynamic, dynamic> map) {
    return AnnotationConfig(
      onIds: map.getStringList(ConfigKeys.annotation.on),
      mode: AnnotationMode.fromKey(map.tryGetString(ConfigKeys.annotation.mode)),
      required: AnnotationConstraint.listFromDynamic(map[ConfigKeys.annotation.required]),
      allowed: AnnotationConstraint.listFromDynamic(map[ConfigKeys.annotation.allowed]),
      forbidden: AnnotationConstraint.listFromDynamic(map[ConfigKeys.annotation.forbidden]),
    );
  }

  /// Parses the 'annotations' list.
  static List<AnnotationConfig> parseList(List<Map<String, dynamic>> list) {
    return list.map(AnnotationConfig.fromMap).toList();
  }
}
