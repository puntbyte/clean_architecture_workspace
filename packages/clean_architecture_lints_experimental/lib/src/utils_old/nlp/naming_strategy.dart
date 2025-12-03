import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/models/configs/naming_conventions_config.dart';
import 'package:architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:architecture_lints/src/utils/nlp/naming_utils.dart';

class NamingStrategy {
  final List<_ComponentPattern> _sortedPatterns;

  NamingStrategy(List<NamingRule> rules) : _sortedPatterns = _createSortedPatterns(rules);

  /// Checks if the [className] found in [actualComponent] matches a
  /// DIFFERENT component pattern more specifically.
  ///
  /// [isInheritanceValid]: If true, the class satisfies the inheritance rules for this component
  /// (e.g. Model extends Entity). In this case, we NEVER yield, because the location is proven correct.
  bool shouldYieldToLocationLint(
      String className,
      ArchComponent actualComponent,
      bool isInheritanceValid,
      ) {
    // 1. Structural Override
    // If inheritance is correct (e.g. Model extends Entity), the file is in the right place.
    // Any naming mismatch is definitely a Naming Error.
    if (isInheritanceValid) return false;

    // 2. Best Guess Pattern Check
    final bestMatchComponent = _getBestGuessComponent(className);

    if (bestMatchComponent == null) return false;
    if (bestMatchComponent == actualComponent) return false;

    // 3. Collision/Ambiguity Check
    if (_matchesComponentPattern(className, actualComponent)) return false;

    // 4. Yield
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
      ..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));

    return patterns;
  }
}

class _ComponentPattern {
  final String pattern;
  final ArchComponent component;

  const _ComponentPattern({required this.pattern, required this.component});
}
