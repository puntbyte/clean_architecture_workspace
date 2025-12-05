import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/member_constraint.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class MemberConfig {
  final List<String> onIds;
  final List<MemberConstraint> required;
  final List<MemberConstraint> allowed;
  final List<MemberConstraint> forbidden;

  const MemberConfig({
    required this.onIds,
    required this.required,
    required this.allowed,
    required this.forbidden,
  });

  factory MemberConfig.fromMap(Map<dynamic, dynamic> map) {
    return MemberConfig(
      onIds: map.getStringList(ConfigKeys.member.on),
      required: MemberConstraint.listFromDynamic(map[ConfigKeys.member.required]),
      allowed: MemberConstraint.listFromDynamic(map[ConfigKeys.member.allowed]),
      forbidden: MemberConstraint.listFromDynamic(map[ConfigKeys.member.forbidden]),
    );
  }
}