import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:meta/meta.dart';

@immutable
class ModuleContext {
  /// The configuration definition (e.g. for 'features').
  final ModuleConfig config;

  /// The specific instance name extracted from the path (e.g. 'auth').
  final String name;

  const ModuleContext({
    required this.config,
    required this.name,
  });

  String get key => config.key; // e.g. 'features'
  bool get isStrict => config.strict;

  /// Determines if this module is allowed to import [other] based on isolation rules.
  ///
  /// Logic:
  /// - If strict mode is OFF, allow.
  /// - If strict mode is ON, and both are the SAME module type (e.g. both features),
  ///   they must be the SAME instance (e.g. both 'auth').
  bool canImport(ModuleContext other) {
    if (!isStrict) return true;

    // Strict Rule: Siblings of the same module type cannot communicate.
    if (key == other.key) {
      return name == other.name;
    }

    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleContext && other.config.key == config.key && other.name == name;

  @override
  int get hashCode => config.key.hashCode ^ name.hashCode;

  @override
  String toString() => '$key($name)';
}
