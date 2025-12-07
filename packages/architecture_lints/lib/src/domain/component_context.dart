// lib/src/domain/component_context.dart

import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/domain/module_context.dart';
import 'package:meta/meta.dart';

@immutable
class ComponentContext {
  /// The absolute file path.
  final String filePath;

  /// The configuration definition.
  final ComponentConfig config;

  /// The vertical slice this component belongs to (optional).
  final ModuleContext? module;

  const ComponentContext({
    required this.filePath,
    required this.config,
    this.module,
  });

  String get id => config.id;

  String get displayName => config.displayName;

  List<String> get patterns => config.patterns;

  List<String> get antipatterns => config.antipatterns;

  List<String> get grammar => config.grammar;

  /// Checks if this component matches a configuration reference ID.
  ///
  /// Supports:
  /// 1. Exact Match: id 'data.repo' == ref 'data.repo'
  /// 2. Parent Check: id 'data.repo' startsWith ref 'data.'
  /// 3. Suffix Check: id 'data.repo' endsWith ref '.repo'
  /// 4. Module Check: module.key 'core' == ref 'core' (NEW)
  bool matchesReference(String referenceId) {
    // 1. Exact Match
    if (id == referenceId) return true;

    // 2. Parent Check (e.g. ref 'data', id 'data.source')
    if (id.startsWith('$referenceId.')) return true;

    // 3. Suffix Check (e.g. ref 'source', id 'data.source')
    if (id.endsWith('.$referenceId')) return true;

    // 4. Middle Segment Check (e.g. ref 'source', id 'data.source.interface')
    // We check for dots on both sides to avoid partial matches (e.g. 'resource' vs 'source')
    if (id.contains('.$referenceId.')) return true;

    // 5. Module Key Check
    if (module != null && module!.key == referenceId) return true;

    return false;
  }

  /// Convenience for checking against a list of references (e.g. allowed list).
  bool matchesAny(List<String> referenceIds) {
    return referenceIds.any(matchesReference);
  }

  @override
  String toString() => 'ComponentContext(id: $id, module: ${module?.name})';
}
