import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class MemberConstraint {
  /// 'method', 'field', 'getter', 'setter', 'constructor'
  final String? kind;

  /// Name pattern (Regex supported) or List of names
  final List<String> identifiers;

  /// 'public', 'private'
  final String? visibility;

  /// 'final', 'const', 'static', 'late'
  final String? modifier;

  const MemberConstraint({
    this.kind,
    this.identifiers = const [],
    this.visibility,
    this.modifier,
  });

  factory MemberConstraint.fromMap(Map<dynamic, dynamic> map) {
    // Handle identifier which can be String or List<String>
    final rawId = map[ConfigKeys.member.identifier];
    List<String> ids = [];
    if (rawId is String) ids.add(rawId);
    if (rawId is List) ids.addAll(rawId.map((e) => e.toString()));

    return MemberConstraint(
      kind: map.tryGetString(ConfigKeys.member.kind),
      identifiers: ids,
      visibility: map.tryGetString(ConfigKeys.member.visibility),
      modifier: map.tryGetString(ConfigKeys.member.modifier),
    );
  }

  static List<MemberConstraint> listFromDynamic(dynamic value) {
    if (value is Map) {
      return [MemberConstraint.fromMap(value)];
    }
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => MemberConstraint.fromMap(e))
          .toList();
    }
    return [];
  }
}