// lib/src/models/error_handlers_config.dart

part of '../error_handlers_config.dart';

/// Represents a specific operation rule (e.g., "try_return Object").
class OperationRule {
  final List<String> operations; // Supports single string or list ['throw', 'rethrow']
  final String? targetType; // Key referencing type_definitions (e.g. 'exception.base')

  const OperationRule({required this.operations, this.targetType});

  factory OperationRule.fromMap(Map<String, dynamic> map) {
    final op = map[ConfigKey.error.operation];
    final opList = op is List ? op.cast<String>() : [op.toString()];

    return OperationRule(
      operations: opList,
      targetType: map.asStringOrNull(ConfigKey.error.targetType),
    );
  }
}

/// Represents a conversion rule (e.g., Exception -> Failure).
class ConversionRule {
  final String fromType;
  final String toType;

  const ConversionRule({required this.fromType, required this.toType});

  factory ConversionRule.fromMap(Map<String, dynamic> map) {
    return ConversionRule(
      fromType: map.asString(ConfigKey.error.fromType),
      toType: map.asString(ConfigKey.error.toType),
    );
  }
}

/// Represents the error handling strategy for a specific component.
class ErrorHandlerRule {
  final String on;
  final String role;
  final List<OperationRule> required;
  final List<OperationRule> forbidden;
  final List<ConversionRule> conversions;

  const ErrorHandlerRule({
    required this.on,
    required this.role,
    this.required = const [],
    this.forbidden = const [],
    this.conversions = const [],
  });

  factory ErrorHandlerRule.fromMap(Map<String, dynamic> map) {
    return ErrorHandlerRule(
      on: map.asString(ConfigKey.rule.on),
      role: map.asString(ConfigKey.error.role),
      required: map.asMapList(ConfigKey.rule.required).map(OperationRule.fromMap).toList(),
      forbidden: map.asMapList(ConfigKey.rule.forbidden).map(OperationRule.fromMap).toList(),
      conversions: map.asMapList(ConfigKey.error.conversions).map(ConversionRule.fromMap).toList(),
    );
  }
}
