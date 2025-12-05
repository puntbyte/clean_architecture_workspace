import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/enums/exception_operation.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ExceptionConstraint {
  /// The parsed operation enum. Null if the YAML string was invalid.
  final ExceptionOperation? operation;

  final String? definition;
  final String? type;

  const ExceptionConstraint({
    required this.operation,
    this.definition,
    this.type,
  });

  factory ExceptionConstraint.fromMap(Map<dynamic, dynamic> map) {
    final rawOp = map.getString(ConfigKeys.exception.operation);

    return ExceptionConstraint(
      // Convert string to Enum immediately during parsing
      operation: ExceptionOperation.fromKey(rawOp),
      definition: map.tryGetString(ConfigKeys.exception.definition),
      type: map.tryGetString(ConfigKeys.exception.type),
    );
  }
}
