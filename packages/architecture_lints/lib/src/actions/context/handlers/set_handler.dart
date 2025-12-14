// lib/src/actions/context/handlers/set_handler.dart

import 'package:architecture_lints/src/actions/context/handlers/variable_handler.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

class SetHandler extends VariableHandler {
  const SetHandler(super.engine);

  @override
  dynamic handle(
    VariableConfig config,
    Map<String, dynamic> context,
    VariableResolver resolver,
  ) {
    final result = <dynamic>{};

    // 1. From
    if (config.from != null) {
      final source = engine.evaluate(config.from!, context);
      if (source is Iterable) {
        result.addAll(source);
      } else if (source != null) {
        result.add(source);
      }
    }

    // 2. Values
    for (final expr in config.values) {
      final val = engine.evaluate(expr, context);
      result.add(val);
    }

    // 3. Spread
    for (final expr in config.spread) {
      final val = engine.evaluate(expr, context);
      if (val is Iterable) {
        result.addAll(val);
      } else if (val != null) {
        result.add(val);
      }
    }

    return result; // Returns Set<dynamic>
  }
}
