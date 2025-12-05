// lib/src/core/resolver/file_resolver.dart

import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/module_resolver.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/domain/module_context.dart';

class FileResolver {
  final ArchitectureConfig config;
  final ModuleResolver _moduleResolver;

  FileResolver(this.config) : _moduleResolver = ModuleResolver(config.modules);

  /// Resolves the full architectural context of a file.
  ComponentContext? resolve(String filePath) {
    // 1. Resolve Config
    final componentConfig = _resolveConfig(filePath);
    if (componentConfig == null) return null;

    // 2. Resolve Module
    final moduleContext = _moduleResolver.resolve(filePath);

    // 3. Create Rich Context
    return ComponentContext(
      filePath: filePath,
      config: componentConfig,
      module: moduleContext,
    );
  }

  ComponentConfig? _resolveConfig(String filePath) {
    ComponentConfig? bestMatch;
    var bestMatchIndex = -1;
    var bestMatchLength = -1;

    final normalizedFile = filePath.replaceAll(r'\', '/');

    for (final component in config.components) {
      if (component.paths.isEmpty) continue;

      for (final path in component.paths) {
        final matchIndex = PathMatcher.getMatchIndex(normalizedFile, path);

        if (matchIndex != -1) {
          if (matchIndex > bestMatchIndex) {
            bestMatchIndex = matchIndex;
            bestMatchLength = path.length;
            bestMatch = component;
          } else if (matchIndex == bestMatchIndex) {
            if (path.length > bestMatchLength) {
              bestMatchLength = path.length;
              bestMatch = component;
            }
          }
        }
      }
    }

    return bestMatch;
  }

  /// Resolves the ModuleContext for a given path, even if it's not a known component.
  ModuleContext? resolveModule(String filePath) {
    return _moduleResolver.resolve(filePath);
  }
}
