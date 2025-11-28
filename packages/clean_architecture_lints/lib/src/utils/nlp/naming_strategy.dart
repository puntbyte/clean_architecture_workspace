import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/configs/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';

/// Encapsulates the logic for identifying if a class name likely belongs to
/// a different architectural component than the one it is currently in.
class NamingStrategy {
  final List<_ComponentPattern> _sortedPatterns;

  NamingStrategy(List<NamingRule> rules) : _sortedPatterns = _createSortedPatterns(rules);

  /// Checks if the [className] found in [actualComponent] matches a
  /// DIFFERENT component pattern more specifically.
  ///
  /// Returns `true` if the naming lint should yield (stop processing).
  bool shouldYieldToLocationLint(String className, ArchComponent actualComponent) {
    // 1. Find the best matching component for this name based on all rules.
    final bestMatchComponent = _getBestGuessComponent(className);

    // If the name doesn't match ANY known pattern, we can't claim it belongs elsewhere.
    if (bestMatchComponent == null) return false;

    // If the name matches the component we are currently in, we definitely don't yield.
    if (bestMatchComponent == actualComponent) return false;

    // 2. Collision/Ambiguity Check:
    // Does the name *also* syntactically match the current component's pattern?
    if (_matchesComponentPattern(className, actualComponent)) {
      return false;
    }

    // 3. Yield:
    // The name does NOT match the current location's pattern,
    // BUT it DOES match another component's pattern.
    return true;
  }

  ArchComponent? _getBestGuessComponent(String className) {
    final bestMatch = _sortedPatterns.firstWhereOrNull(
          (p) => NamingUtils.validateName(name: className, template: p.pattern),
    );
    return bestMatch?.component;
  }

  bool _matchesComponentPattern(String className, ArchComponent component) {
    final rules = _sortedPatterns.where((p) => p.component == component);
    return rules.any((p) => NamingUtils.validateName(name: className, template: p.pattern));
  }

  static List<_ComponentPattern> _createSortedPatterns(List<NamingRule> rules) {
    final patterns = rules
        .expand((rule) {
      return rule.on.map((componentId) {
        final component = ArchComponent.fromId(componentId);
        return component != ArchComponent.unknown
            ? _ComponentPattern(pattern: rule.pattern, component: component)
            : null;
      });
    })
        .whereNotNull()
        .toList()
    // Sort by length descending (Specific > Generic)
      ..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));

    return patterns;
  }
}

class _ComponentPattern {
  final String pattern;
  final ArchComponent component;

  const _ComponentPattern({required this.pattern, required this.component});
}