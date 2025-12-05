import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:architecture_lints/src/domain/module_context.dart';

class ModuleResolver {
  final List<ModuleConfig> modules;

  const ModuleResolver(this.modules);

  /// Resolves the specific instance name of a module from a file path.
  ModuleContext? resolve(String filePath) {
    final normalizedFile = filePath.replaceAll(r'\', '/');

    for (final module in modules) {
      // Case 1: Dynamic Module (e.g. features/{{name}})
      if (module.path.contains('{{name}}')) {
        final pattern = PathMatcher.escapeRegex(module.path).replaceAll(r'\{\{name\}\}', '([^/]+)');

        // Look for the module pattern surrounded by slashes
        final regex = RegExp('/$pattern/');
        final match = regex.firstMatch(normalizedFile);

        if (match != null && match.groupCount >= 1) {
          return ModuleContext(
            config: module,
            name: match.group(1)!,
          );
        }
      }
      // Case 2: Static Module (e.g. core)
      else {
        // Check if the file is inside the module directory
        // We check for '/core/' to avoid partial matches like 'score' matching 'core'
        if (normalizedFile.contains('/${module.path}/')) {
          return ModuleContext(
            config: module,
            name: module.key, // For static modules, the instance name is the key
          );
        }
      }
    }
    return null;
  }
}
