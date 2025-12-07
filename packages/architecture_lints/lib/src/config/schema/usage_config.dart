// lib/src/config/schema/usage_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/usage_constraint.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class UsageConfig {
  final List<String> onIds;
  final List<UsageConstraint> forbidden;

  const UsageConfig({
    required this.onIds,
    required this.forbidden,
  });

  factory UsageConfig.fromMap(Map<dynamic, dynamic> map) {
    return UsageConfig(
      onIds: map.getStringList(ConfigKeys.usage.on),
      forbidden: map.getMapList(ConfigKeys.usage.forbidden).map(UsageConstraint.fromMap).toList(),
    );
  }

  /// Parses the 'usages' list.
  static List<UsageConfig> parseList(List<Map<String, dynamic>> list) {
    return list.map(UsageConfig.fromMap).toList();
  }
}
