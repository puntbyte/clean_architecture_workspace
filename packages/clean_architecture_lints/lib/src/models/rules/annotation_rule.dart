// lib/src/models/rules/annotation_rule.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

/// Represents a single, complete annotation rule for an architectural component.
class AnnotationRule {
  /// The architectural component to apply the rule to (e.g., 'use_case').
  final String on;
  /// A list of annotations that are required to be present on the class.
  final List<AnnotationDetail> required;
  /// A list of annotations that are forbidden from being on the class.
  final List<AnnotationDetail> forbidden;
  /// A list of annotations that are suggested but not enforced. (For future use).
  final List<AnnotationDetail> optional;

  const AnnotationRule({
    required this.on,
    this.required = const [],
    this.forbidden = const [],
    this.optional = const [],
  });

  factory AnnotationRule.fromMap(Map<String, dynamic> map) {
    List<AnnotationDetail> parseDetails(String key) {
      final data = (map[key] as List<dynamic>?) ?? [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(AnnotationDetail.fromMap)
          .toList();
    }

    return AnnotationRule(
      on: map.getString('on'),
      required: parseDetails('required'),
      forbidden: parseDetails('forbidden'),
      optional: parseDetails('optional'),
    );
  }
}

/// Represents a single annotation's details (its text and import path).
class AnnotationDetail {
  final String text;
  final String? import;

  const AnnotationDetail({required this.text, this.import});

  factory AnnotationDetail.fromMap(Map<String, dynamic> map) {
    return AnnotationDetail(
      text: map.getString('text'),
      import: map.getOptionalString('import'),
    );
  }
}
