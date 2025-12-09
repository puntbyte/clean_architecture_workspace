import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/core/resolver/refinement/refinement_context.dart';
import 'package:architecture_lints/src/core/resolver/refinement/score_log.dart';


abstract class RefinementStrategy {
  /// Evaluates the candidate and updates the [log].
  void evaluate({
    required ScoreLog log,
    required RefinementContext context,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
  });
}