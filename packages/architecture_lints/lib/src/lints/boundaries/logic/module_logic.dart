import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:meta/meta.dart';

mixin ModuleLogic {
  /// Resolves the specific instance name of a module from a file path.
  ///
  /// Example:
  /// Config: features -> 'features/{{name}}'
  /// File: 'lib/features/login/data/...'
  /// Returns: ModuleInstance(config: features, name: 'login')
  ModuleInstance? resolveModuleInstance(String filePath, List<ModuleConfig> modules) {
    final normalizedFile = filePath.replaceAll(r'\', '/');

    for (final module in modules) {
      // We only care about modules that use wildcards (like {{name}})
      // because static modules (like 'core') don't have siblings to isolate against.
      if (!module.path.contains('{{name}}')) continue;

      // Create a regex to extract the name
      // Path: 'features/{{name}}' -> Regex: 'features/([^/]+)'
      final pattern = PathMatcher.escapeRegex(module.path).replaceAll(r'\{\{name\}\}', '([^/]+)');

      // Check if file contains this pattern
      // We look for '/features/login/' boundaries to ensure we match directory segments
      final regex = RegExp('/$pattern/');
      final match = regex.firstMatch(normalizedFile);

      if (match != null && match.groupCount >= 1) {
        return ModuleInstance(
          config: module,
          name: match.group(1)!, // e.g. 'login'
        );
      }
    }
    return null;
  }
}

@immutable
class ModuleInstance {
  final ModuleConfig config;
  final String name;

  const ModuleInstance({required this.config, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuleInstance && other.config.key == config.key && other.name == name;

  @override
  int get hashCode => config.key.hashCode ^ name.hashCode;
}
