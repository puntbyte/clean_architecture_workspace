import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ExceptionConversion {
  final String fromDefinition;
  final String toDefinition;

  const ExceptionConversion({
    required this.fromDefinition,
    required this.toDefinition,
  });

  factory ExceptionConversion.fromMap(Map<dynamic, dynamic> map) {
    return ExceptionConversion(
      fromDefinition: map.getString(ConfigKeys.exception.fromDefinition),
      toDefinition: map.getString(ConfigKeys.exception.toDefinition),
    );
  }
}