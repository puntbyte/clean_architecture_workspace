// lib/src/models/configs/annotations_config.dart

import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/utils_old/config/config_keys.dart';
import 'package:architecture_lints/src/utils_old/extensions/iterable_extension.dart';
import 'package:architecture_lints/src/utils_old/extensions/json_map_extension.dart';
import 'package:architecture_lints/src/utils_old/extensions/json_map_extension.dart';

part '../details/annotation_detail.dart';

part '../rules/annotation_rule.dart';

/// The parent configuration class for all annotation rules.
class AnnotationsConfig {
  final List<AnnotationRule> rules;

  const AnnotationsConfig({required this.rules});

  /// Factory that parses the `annotations` block from YAML.
  factory AnnotationsConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = map.asMapList(ConfigKey.root.annotations);

    return AnnotationsConfig(
      rules: ruleList.map(AnnotationRule.tryFromMap).whereType<AnnotationRule>().toList(),
    );
  }

  /// Finds the specific rule for a given architectural component.
  AnnotationRule? ruleFor(ArchComponent component) {
    return rules.firstWhereOrNull((rule) => rule.on.contains(component.id));
  }

  /// Returns all required annotations for a specific component.
  List<AnnotationDetail> requiredFor(ArchComponent component) {
    return ruleFor(component)?.required ?? [];
  }
}
