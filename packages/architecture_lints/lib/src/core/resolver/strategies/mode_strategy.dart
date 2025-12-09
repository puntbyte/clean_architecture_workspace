import 'package:architecture_lints/src/config/enums/component_mode.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_context.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_strategy.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_log.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_weight.dart';

class ModeStrategy implements RefinementStrategy {
  @override
  void evaluate({
    required ScoreLog log,
    required RefinementContext context,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
  }) {
    final mode = log.candidate.component.mode;

    if (mode == ComponentMode.file) {
      log.add(ScoreWeight.strong.value, 'MODE: File');
    } else if (mode == ComponentMode.part) {
      log.add(-ScoreWeight.strong.value, 'MODE: Part');
    }
  }
}