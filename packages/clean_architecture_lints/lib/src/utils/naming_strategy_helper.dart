// lib/src/utils/naming_strategy_helper.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';

class NamingStrategyHelper {
  final List<ComponentPattern> _sortedPatterns;

  NamingStrategyHelper(List<NamingRule> rules)
      : _sortedPatterns = _createSortedPatterns(rules);

  /// Finds the best matching component for a given class name.
  ComponentPattern? getBestMatch(String className) {
    return _sortedPatterns.firstWhereOrNull(
          (p) => NamingUtils.validateName(name: className, template: p.pattern),
    );
  }

  /// Checks if the name is likely a mislocation rather than a naming error.
  ///
  /// Returns `true` if the linter should STOP (skip reporting) because the file
  /// seems to belong to another component entirely.
  bool shouldYieldToLocationLint(String className, ArchComponent actualComponent) {
    final bestMatch = getBestMatch(className);

    if (bestMatch != null && bestMatch.component != actualComponent) {
      // If the actual component matches a pattern, check specificity.
      final actualPattern = _sortedPatterns.firstWhereOrNull(
            (p) => p.component == actualComponent &&
            NamingUtils.validateName(name: className, template: p.pattern),
      );

      if (actualPattern != null) {
        // If actual pattern is equally or more specific than the best match,
        // it's ambiguous (e.g. Login matches {{name}} for Entity and UseCase).
        // We assume it's NOT a location error.
        if (actualPattern.pattern.length >= bestMatch.pattern.length) {
          return false;
        }
      }

      // If we are here, the name matches ANOTHER component significantly better
      // than the current one. Yield to the Location lint.
      return true;
    }

    return false;
  }

  static List<ComponentPattern> _createSortedPatterns(List<NamingRule> rules) {
    final patterns = rules.expand((rule) {
      return rule.on.map((componentId) {
        final component = ArchComponent.fromId(componentId);
        return component != ArchComponent.unknown
            ? ComponentPattern(pattern: rule.pattern, component: component)
            : null;
      });
    }).whereNotNull().toList();

    // Sort by length descending (Specificity).
    patterns.sort((a, b) => b.pattern.length.compareTo(a.pattern.length));
    return patterns;
  }
}

class ComponentPattern {
  final String pattern;
  final ArchComponent component;
  const ComponentPattern({required this.pattern, required this.component});
}