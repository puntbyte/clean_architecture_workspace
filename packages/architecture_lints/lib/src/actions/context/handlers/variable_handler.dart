// lib/src/actions/context/handlers/variable_handler.dart

import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

abstract class VariableHandler {
  final ExpressionEngine engine;

  const VariableHandler(this.engine);

  /// Handles the resolution of a specific variable type.
  /// [resolver] is passed to allow recursive resolution (e.g. for list items).
  dynamic handle(
    VariableConfig config,
    Map<String, dynamic> context,
    VariableResolver resolver,
  );

  /// Helper to build the rich metadata map for collections.
  Map<String, dynamic> buildListMeta(List<dynamic> items) => {
    'items': items,
    'length': items.length,
    'isEmpty': items.isEmpty,
    'isNotEmpty': items.isNotEmpty,
    'hasMany': items.length > 1,
    'isSingle': items.length == 1,
  };
}
