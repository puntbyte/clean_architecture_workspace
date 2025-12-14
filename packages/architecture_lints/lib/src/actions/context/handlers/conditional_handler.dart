import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

class ConditionalHandler {
  final ExpressionEngine engine;

  ConditionalHandler(this.engine);

  VariableConfig? handle(List<VariableSelect> select, Map<String, dynamic> context) {
    for (var i = 0; i < select.length; i++) {
      final branch = select[i];
      final condition = branch.condition;

      // 1. Else / Fallback
      if (condition == null) return branch.result;

      // 2. If condition
      try {
        // Inspect context before eval
        // final source = context['source'];
        // print('  [$i] Context Source Type: ${source.runtimeType}');

        final result = engine.evaluate(condition, context);

        if (result == true) return branch.result;
      } catch (e, stack) {
        // print(stack);
        // Continue to next branch on error
        continue;
      }
    }

    return null;
  }
}
