// lib/src/models/details/inheritance_detail.dart

part of '../inheritances_config.dart';

class InheritanceDetail {
  final String? name;
  final String? import;
  final String? component;

  const InheritanceDetail({this.name, this.import, this.component});

  static List<InheritanceDetail> fromMapWithExpansion(Map<String, dynamic> map) {
    // Access ConfigKey from parent context
    final import = map.asStringOrNull(ConfigKey.rule.import);
    final component = map.asStringOrNull(ConfigKey.rule.component);

    final nameValue = map[ConfigKey.rule.name];
    if (nameValue is List) {
      return nameValue
          .map(
            (n) => InheritanceDetail(
              name: n.toString(),
              import: import,
              component: component,
            ),
          )
          .toList();
    }

    final singleDetail = InheritanceDetail(
      name: map.asStringOrNull(ConfigKey.rule.name),
      import: import,
      component: component,
    );

    if (singleDetail.name == null && singleDetail.component == null) return [];

    return [singleDetail];
  }
}
