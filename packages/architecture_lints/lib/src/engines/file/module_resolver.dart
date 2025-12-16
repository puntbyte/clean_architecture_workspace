// lib/src/engines/file/module_resolver.dart

import 'package:architecture_lints/src/context/module_context.dart';
import 'package:architecture_lints/src/schema/constants/regexps.dart';
import 'package:architecture_lints/src/schema/definitions/module_definition.dart';
import 'package:architecture_lints/src/schema/enums/placeholder_token.dart';

class ModuleResolver {
  final List<ModuleDefinition> modules;

  const ModuleResolver(this.modules);

  /// Resolves the module context for a specific file path.
  ModuleContext? resolve(String filePath) {
    final normalizedFile = filePath.replaceAll(r'\', '/');

    // We prioritize matches inside the 'lib/' directory to avoid matching
    // project root folders that happen to have the same name.
    final libIndex = normalizedFile.indexOf('/lib/');
    final searchStart = libIndex == -1 ? 0 : libIndex;

    final placeholder = PlaceholderToken.name.template; // {{name}}

    for (final module in modules) {
      // 1. Dynamic Modules (e.g. features/{{name}})
      if (module.path.contains(placeholder)) {
        // Step A: Escape the config path (turns 'features/{{name}}' into 'features/\{\{name\}\}')
        final escapedPath = RegexConstants.escape(module.path);

        // Step B: Escape the placeholder itself to match the escaped path
        final escapedPlaceholder = RegexConstants.escape(placeholder);

        // Step C: Replace the placeholder with a capture group
        // Pattern becomes: features/([^/]+)
        final pattern = escapedPath.replaceAll(
          escapedPlaceholder,
          '(${RegexConstants.pathSegment})', // Capture Group around pathSegment
        );

        // Step D: Match against file path
        // We look for the pattern surrounded by slashes OR at the start of a relative path
        // e.g. /features/auth/
        final regex = RegExp('/$pattern/');
        final match = regex.firstMatch(normalizedFile.substring(searchStart));

        if (match != null && match.groupCount >= 1) {
          return ModuleContext(
            definition: module,
            name: match.group(1)!,
          );
        }
      }
      // 2. Static Modules (e.g. core)
      else {
        // Strict directory match: must be surrounded by slashes to avoid partials
        // e.g. /core/ matches, but /score/ does not.
        if (normalizedFile.indexOf('/${module.path}/', searchStart) != -1) {
          return ModuleContext(
            definition: module,
            name: module.key,
          );
        }
      }
    }
    return null;
  }
}
