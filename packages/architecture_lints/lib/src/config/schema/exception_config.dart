import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/exception_constraint.dart';
import 'package:architecture_lints/src/config/schema/exception_conversion.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ExceptionConfig {
  final List<String> onIds;
  final String? role;
  final List<ExceptionConstraint> required;
  final List<ExceptionConstraint> forbidden;
  final List<ExceptionConversion> conversions;

  const ExceptionConfig({
    required this.onIds,
    required this.required,
    required this.forbidden,
    required this.conversions,
    this.role,
  });

  factory ExceptionConfig.fromMap(Map<dynamic, dynamic> map) {
    return ExceptionConfig(
      onIds: map.getStringList(ConfigKeys.exception.on),
      role: map.tryGetString(ConfigKeys.exception.role),
      required: _parseList(map[ConfigKeys.exception.required]),
      forbidden: _parseList(map[ConfigKeys.exception.forbidden]),
      conversions: _parseConversions(map[ConfigKeys.exception.conversions]),
    );
  }

  static List<ExceptionConstraint> _parseList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(ExceptionConstraint.fromMap)
          .toList();
    }
    // Handle single object shorthand
    if (value is Map) {
      return [ExceptionConstraint.fromMap(value)];
    }
    return [];
  }

  static List<ExceptionConversion> _parseConversions(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(ExceptionConversion.fromMap)
          .toList();
    }
    return [];
  }
}