import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_context.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_strategy.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_log.dart';

class PathStrategy implements RefinementStrategy {
  @override
  void evaluate({
    required ScoreLog log,
    required RefinementContext context,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
  }) {
    final candidate = log.candidate;
    // Base Score: Depth * 10 + Length
    final score = (candidate.matchIndex * 10.0) + candidate.matchLength;
    log.add(score, 'PATH: Idx ${candidate.matchIndex}, Len ${candidate.matchLength}');
  }
}