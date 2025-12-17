// lib/src/config/schema/action_definition.dart

import 'package:architecture_lints/src/schema/definitions/variable_definition.dart';
import 'package:architecture_lints/src/schema/descriptors/action_source.dart';
import 'package:architecture_lints/src/schema/descriptors/action_target.dart';
import 'package:architecture_lints/src/schema/descriptors/action_trigger.dart';
import 'package:architecture_lints/src/schema/descriptors/action_write.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ActionDefinition {
  final String id;
  final String description;
  final ActionTrigger trigger;
  final ActionSource source;
  final ActionTarget target;
  final ActionWrite write;
  final Map<String, VariableDefinition> variables;
  final String templateId;
  final bool debug;
  final bool format;
  final int? formatLineLength;

  const ActionDefinition({
    required this.id,
    required this.description,
    required this.trigger,
    required this.source,
    required this.target,
    required this.write,
    required this.variables,
    required this.templateId,
    this.debug = false,
    this.format = false,
    this.formatLineLength,
  });

  factory ActionDefinition.fromMap(String id, Map<dynamic, dynamic> map) {
    // parse optional int for line length
    int? parseLineLength(dynamic raw) {
      if (raw == null) return null;
      if (raw is int) return raw;
      final s = raw.toString();
      return int.tryParse(s);
    }

    return ActionDefinition(
      id: id,
      description: map.getString('description', fallback: 'Fix issue'),
      trigger: ActionTrigger.fromMap(map.getMap('trigger')),
      source: ActionSource.fromMap(map.getMap('source')),
      target: ActionTarget.fromMap(map.getMap('target')),
      write: ActionWrite.fromMap(map.getMap('write')),
      variables: _parseVariables(map['variables']),
      templateId: map.mustGetString('template_id'),
      debug: map.getBool('debug'),
      format: map.getBool('format'),
      formatLineLength: parseLineLength(map.tryGetString('format_line_length')),
    );
  }

  static List<ActionDefinition> parseMap(Map<String, dynamic> map) =>
      map.entries.map((e) => ActionDefinition.fromMap(e.key, e.value as Map)).toList();

  static Map<String, VariableDefinition> _parseVariables(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, VariableDefinition>{};
    raw.forEach((key, value) {
      final cleanKey = key.toString().startsWith('.')
          ? key.toString().substring(1)
          : key.toString();
      result[cleanKey] = VariableDefinition.fromDynamic(value);
    });
    return result;
  }
}
