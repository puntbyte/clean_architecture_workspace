// lib/src/domain/component_context.dart

import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/context/module_context.dart';
import 'package:meta/meta.dart';

@immutable
class ComponentContext {
  final String filePath;
  final ComponentDefinition definition;
  final ModuleContext? module;
  final String? debugScoreLog;

  const ComponentContext({
    required this.filePath,
    required this.definition,
    this.module,
    this.debugScoreLog,
  });

  String get id => definition.id;

  String get displayName => definition.displayName;

  List<String> get patterns => definition.patterns;

  List<String> get antipatterns => definition.antipatterns;

  List<String> get grammar => definition.grammar;

  bool matchesReference(String referenceId) {
    if (module != null && module!.key == referenceId) return true;
    if (id == referenceId) return true;

    final idSegments = id.split('.');
    final refSegments = referenceId.split('.');

    if (refSegments.length > idSegments.length) return false;

    for (var i = 0; i <= idSegments.length - refSegments.length; i++) {
      var match = true;
      for (var j = 0; j < refSegments.length; j++) {
        if (idSegments[i + j] != refSegments[j]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }

  bool matchesAny(List<String> referenceIds) => referenceIds.any(matchesReference);

  @override
  String toString() => 'ComponentContext(id: $id, module: ${module?.name})';
}
