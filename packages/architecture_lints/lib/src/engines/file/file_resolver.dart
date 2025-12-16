// lib/src/engines/file/file_resolver.dart

import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/context/module_context.dart';
import 'package:architecture_lints/src/engines/file/file.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';

class FileResolver {
  final ArchitectureConfig config;
  final ModuleResolver _moduleResolver;

  FileResolver(this.config) : _moduleResolver = ModuleResolver(config.modules);

  /// Standard resolution (Path only). Used when AST is not available.
  /// Returns the "Best Path Match" candidate.
  ComponentContext? resolve(String filePath) {
    // 1. Resolve Module (Vertical Slice)
    final moduleContext = _moduleResolver.resolve(filePath);

    // 2. Resolve Component (Horizontal Layer)
    final componentConfig = _resolveConfig(filePath);

    // Even if componentConfig is null, we might have a module (Orphan in Module).
    // If both are null, it's a complete Orphan.
    if (componentConfig == null && moduleContext == null) return null;

    // Note: We return Context even if componentConfig is null,
    // provided we found a Module. This allows OrphanFileRule to report "Inside Module but unknown component".
    // However, most rules expect componentConfig to be non-null.
    // The previous logic returned null if config was null. Let's stick to that for safety
    // unless you specifically want partial contexts.
    if (componentConfig == null) return null;

    return ComponentContext(
      filePath: filePath,
      definition: componentConfig,
      module: moduleContext,
    );
  }

  /// Returns ALL components that match the file path.
  List<Candidate> resolveAllCandidates(String filePath) {
    final normalizedFile = filePath.replaceAll(r'\', '/');
    final matches = <Candidate>[];

    for (final component in config.components) {
      if (component.paths.isEmpty) continue;

      for (final path in component.paths) {
        final matchIndex = PathMatcher.getMatchIndex(normalizedFile, path);

        if (matchIndex != -1) {
          matches.add(
            Candidate(
              component: component,
              matchLength: path.length,
              matchIndex: matchIndex,
            ),
          );

          // Optimization: Once a component matches a file path via one rule,
          // we don't need to check its other path aliases for the same file.
          break;
        }
      }
    }
    return matches;
  }

  ComponentDefinition? _resolveConfig(String filePath) {
    ComponentDefinition? bestMatch;
    var bestMatchIndex = -1;
    var bestMatchLength = -1;

    final normalizedFile = filePath.replaceAll(r'\', '/');

    for (final component in config.components) {
      if (component.paths.isEmpty) continue;

      for (final path in component.paths) {
        final matchIndex = PathMatcher.getMatchIndex(normalizedFile, path);

        if (matchIndex != -1) {
          // Priority 1: Depth (The match that appears latest in the string)
          // e.g. 'domain/entities' (index 20) vs 'domain' (index 10)
          if (matchIndex > bestMatchIndex) {
            bestMatchIndex = matchIndex;
            bestMatchLength = path.length;
            bestMatch = component;
          }
          // Priority 2: Length (If they start at same index, pick the longer path)
          // e.g. 'common/widgets' vs 'common'
          else if (matchIndex == bestMatchIndex) {
            if (path.length > bestMatchLength) {
              bestMatchLength = path.length;
              bestMatch = component;
            }
            // Priority 3: ID Specificity (Tie-breaker for co-located components)
            // e.g. 'data.source.impl' vs 'data.source' (if paths are identical)
            else if (path.length == bestMatchLength) {
              if (component.id.length > (bestMatch?.id.length ?? 0)) {
                bestMatch = component;
              }
            }
          }
        }
      }
    }

    return bestMatch;
  }

  ModuleContext? resolveModule(String filePath) => _moduleResolver.resolve(filePath);
}

/// A potential match for a file.
class Candidate implements Comparable<Candidate> {
  /// The component configuration.
  final ComponentDefinition component;

  /// Length of the path segment matched (Longer = More Specific).
  final int matchLength;

  /// Start index of the match (Higher/Deeper = More Specific).
  /// e.g. 'domain/entities' (index 10) is better than 'domain' (index 0).
  final int matchIndex;

  Candidate({
    required this.component,
    required this.matchLength,
    required this.matchIndex,
  });

  @override
  int compareTo(Candidate other) {
    // 1. Specificity: Deeper matches win
    final indexCmp = matchIndex.compareTo(other.matchIndex);
    if (indexCmp != 0) return indexCmp;

    // 2. Length: Longer path definition wins
    final lenCmp = matchLength.compareTo(other.matchLength);
    if (lenCmp != 0) return lenCmp;

    // 3. ID Length: Tie-breaker for co-located components (Child > Parent)
    // e.g. 'data.source.implementation' > 'data.source'
    return component.id.length.compareTo(other.component.id.length);
  }

  @override
  String toString() => 'Candidate(${component.id}, score: $matchIndex/$matchLength)';
}
