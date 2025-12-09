import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_context.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_strategy.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_log.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_weight.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';

class InheritanceStrategy with InheritanceLogic implements RefinementStrategy {
  @override
  void evaluate({
    required ScoreLog log,
    required RefinementContext context,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
  }) {
    final element = context.mainElement;
    if (element is! InterfaceElement) return;

    final componentId = log.candidate.component.id;

    final inheritanceRules = config.inheritances.where(
          (r) => r.onIds.contains(componentId),
    );

    for (final rule in inheritanceRules) {
      if (rule.required.isNotEmpty) {
        if (satisfiesRule(element, rule, config, fileResolver)) {
          final requiresComponent = rule.required.any((d) => d.component != null);
          if (requiresComponent) {
            // Stronger signal: Implements a specific architectural component
            log.add(ScoreWeight.critical.value, 'INHERIT: Component Req Met');
          } else {
            // Weaker signal: Implements a general type
            log.add(ScoreWeight.strong.value, 'INHERIT: Type Req Met');
          }
        } else {
          // If a required rule fails, this is likely not the component
          log.add(-ScoreWeight.strong.value, 'INHERIT: Req Failed');
        }
      }
    }
  }
}