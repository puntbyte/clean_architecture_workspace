import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_context.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_strategy.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_log.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_weight.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';

class NamingStrategy with NamingLogic implements RefinementStrategy {
  @override
  void evaluate({
    required ScoreLog log,
    required RefinementContext context,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
  }) {
    final patterns = log.candidate.component.patterns;
    final name = context.mainName;

    if (patterns.isEmpty || name == null) return;

    for (final p in patterns) {
      if (validateName(name, p)) {
        // Boost specific patterns (longer) over generic ones
        final score = ScoreWeight.strong.value + p.length;
        log.add(score, 'NAME: Matched "$p"');
        return;
      }
    }

    // Mild penalty: Just because name doesn't match doesn't mean it's NOT this component
    // (could be a typo by user). Do not Veto.
    log.add(-5.0, 'NAME: No match');
  }
}