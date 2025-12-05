// lib/src/common/annotation_mode.dart

import 'package:collection/collection.dart';

enum AnnotationMode {
  strict('strict'),
  implicit('implicit')
  ;

  final String yamlKey;

  const AnnotationMode(this.yamlKey);

  static AnnotationMode fromKey(String? key) {
    return AnnotationMode.values.firstWhereOrNull((e) => e.yamlKey == key) ??
        AnnotationMode.implicit;
  }
}
