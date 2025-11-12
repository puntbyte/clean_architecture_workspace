// lib/src/models/annotations_config.dart

import 'package:clean_architecture_lints/src/models/rules/annotation_rule.dart';

/// The parent configuration class for all annotation rules.
class AnnotationsConfig {
  final List<AnnotationRule> rules;

  const AnnotationsConfig({required this.rules});

  /// A helper to find all required annotations for a specific component.
  List<AnnotationDetail> requiredFor(String component) {
    return rules
        .firstWhere((rule) => rule.on == component, orElse: () => const AnnotationRule(on: ''))
        .required;
  }

  factory AnnotationsConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = (map['rules'] as List<dynamic>?) ?? [];
    return AnnotationsConfig(
      rules: ruleList
          .whereType<Map<String, dynamic>>()
          .map(AnnotationRule.fromMap)
          .toList(),
    );
  }
}
