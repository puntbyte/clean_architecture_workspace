// lib/src/core/resolver/file_resolver.dart

import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/module_resolver.dart';
import 'package:architecture_lints/src/core/resolver/path_matcher.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:architecture_lints/src/domain/module_context.dart';
import 'package:architecture_lints/src/utils/naming_utils.dart';
import 'package:path/path.dart' as p;

class FileResolver {
  final ArchitectureConfig config;
  final ModuleResolver _moduleResolver;

  FileResolver(this.config) : _moduleResolver = ModuleResolver(config.modules);

  ComponentContext? resolve(String filePath) {
    final componentConfig = _resolveConfig(filePath);
    if (componentConfig == null) return null;

    final moduleContext = _moduleResolver.resolve(filePath);

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

    // Guess class name from file name (auth_source.dart -> AuthSource)
    // This is a heuristic to help break ties.
    final filename = p.basenameWithoutExtension(normalizedFile);
    final guessedClassName = _toPascalCase(filename);

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
            // TIE-BREAKER: Paths are identical (Co-located files).
            else if (path.length == bestMatchLength && bestMatch != null) {
              // Priority 1: Check Hierarchy (Child > Parent)
              if (component.id.startsWith('${bestMatch.id}.')) {
                bestMatch = component;
              } else if (bestMatch.id.startsWith('${component.id}.')) {
                // Keep bestMatch (it is the child)
              }
              // Priority 2: Pattern Match on Guessed Class Name
              else {
                // Does 'AuthSource' match '{{name}}Source'? Yes.
                // Does 'DefaultAuthSource' match '{{name}}Source'? Yes.
                // Does 'AuthSource' match '{{affix}}{{name}}Source'? Yes.
                // This heuristic is imperfect but can help if one pattern is strict and one is loose.

                final currentMatches = _matchesAnyPattern(guessedClassName, bestMatch.patterns);
                final newMatches = _matchesAnyPattern(guessedClassName, component.patterns);

                // If the new component matches the file pattern but the current best doesn't, switch.
                if (newMatches && !currentMatches) {
                  bestMatch = component;
                }
              }
            }
          }
        }
      }
    }

    return bestMatch;
  }

  bool _matchesAnyPattern(String name, List<String> patterns) {
    if (patterns.isEmpty) return false;
    for (final p in patterns) {
      if (NamingUtils.validateName(name: name, template: p)) return true;
    }
    return false;
  }

  String _toPascalCase(String text) {
    return text.split('_').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join();
  }

  ModuleContext? resolveModule(String filePath) {
    return _moduleResolver.resolve(filePath);
  }
}
