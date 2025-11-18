// lib/src/models/annotations_config.dart

import 'package:clean_architecture_lints/src/utils/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'details/annotation_detail.dart';
part 'rules/annotation_rule.dart';

/// The parent configuration class for all annotation rules.
class AnnotationsConfig {
  final List<AnnotationRule> rules;

  const AnnotationsConfig({required this.rules});

  /// Finds the specific rule for a given architectural component ID.
  AnnotationRule? ruleFor(String componentId) {
    return rules.firstWhereOrNull((rule) => rule.on.contains(componentId));
  }

  /// Returns all required annotations for a specific component.
  List<AnnotationDetail> requiredFor(String componentId) {
    return ruleFor(componentId)?.required ?? [];
  }

  /// Factory that parses the `annotations` block from YAML.
  factory AnnotationsConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = map.asMapList(ConfigKey.root.annotations);

    return AnnotationsConfig(
      rules: ruleList
          .map(AnnotationRule.tryFromMap)
          .whereType<AnnotationRule>()
          .toList(),
    );
  }
}
