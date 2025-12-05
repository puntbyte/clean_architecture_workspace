import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class UsageConstraint {
  /// 'access' or 'instantiation'
  final String kind;

  /// Reference to a key in 'services' (for access checks)
  final String? definition;

  /// Reference to an architectural component (for instantiation checks)
  final List<String> components;

  const UsageConstraint({
    required this.kind,
    this.definition,
    this.components = const [],
  });

  factory UsageConstraint.fromMap(Map<dynamic, dynamic> map) {
    return UsageConstraint(
      kind: map.getString(ConfigKeys.usage.kind),
      definition: map.tryGetString(ConfigKeys.usage.definition),
      components: map.getStringList(ConfigKeys.usage.component),
    );
  }
}
