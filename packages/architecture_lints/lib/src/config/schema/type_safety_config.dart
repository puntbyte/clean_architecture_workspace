import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/type_safety_constraint.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class TypeSafetyConfig {
  final List<String> onIds;
  final List<TypeSafetyConstraint> allowed;
  final List<TypeSafetyConstraint> forbidden;

  const TypeSafetyConfig({
    required this.onIds,
    required this.allowed,
    required this.forbidden,
  });

  factory TypeSafetyConfig.fromMap(Map<dynamic, dynamic> map) {
    return TypeSafetyConfig(
      onIds: map.getStringList(ConfigKeys.typeSafety.on),
      allowed: TypeSafetyConstraint.listFromDynamic(map[ConfigKeys.typeSafety.allowed]),
      forbidden: TypeSafetyConstraint.listFromDynamic(map[ConfigKeys.typeSafety.forbidden]),
    );
  }
}