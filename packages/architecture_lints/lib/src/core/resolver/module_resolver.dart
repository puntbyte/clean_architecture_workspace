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
      if (!module.path.contains('{{name}}')) continue;

      final pattern = PathMatcher.escapeRegex(module.path)
          .replaceAll(r'\{\{name\}\}', r'([^/]+)');

      final regex = RegExp('/$pattern/');
      final match = regex.firstMatch(normalizedFile);

      if (match != null && match.groupCount >= 1) {
        // Return ModuleContext
        return ModuleContext(
          config: module,
          name: match.group(1)!,
        );
      }
    }
    return null;
  }
}