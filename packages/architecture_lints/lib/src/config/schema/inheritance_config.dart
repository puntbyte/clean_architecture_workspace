import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class InheritanceConfig {
  /// The component IDs this rule applies to.
  final List<String> onIds;

  /// The class MUST inherit from one of these.
  final Definition required;

  /// The class MAY ONLY inherit from one of these (Whitelist).
  final Definition allowed;

  /// The class MUST NOT inherit from these (Blacklist).
  final Definition forbidden;

  const InheritanceConfig({
    required this.onIds,
    required this.required,
    required this.allowed,
    required this.forbidden,
  });

  factory InheritanceConfig.fromMap(Map<dynamic, dynamic> map) {
    return InheritanceConfig(
      onIds: map.getStringList(ConfigKeys.inheritance.on),
      required: Definition.fromDynamic(map[ConfigKeys.inheritance.required]),
      allowed: Definition.fromDynamic(map[ConfigKeys.inheritance.allowed]),
      forbidden: Definition.fromDynamic(map[ConfigKeys.inheritance.forbidden]),
    );
  }

  /// Parses the 'inheritances' list.
  static List<InheritanceConfig> parseList(List<Map<String, dynamic>> list) {
    return list.map(InheritanceConfig.fromMap).toList();
  }
}
