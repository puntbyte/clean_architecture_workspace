import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:architecture_lints/src/actions/context/handlers/variable_handler.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/parameter_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

class ListHandler extends VariableHandler {
  const ListHandler(super.engine);

  @override
  dynamic handle(
    VariableConfig config,
    Map<String, dynamic> context,
    VariableResolver resolver,
  ) {
    final result = <dynamic>[];

    // A. From Source
    if (config.from != null) {
      // print('[ListHandler] Evaluating from: "${config.from}"');
      var source = engine.evaluate(config.from!, context);

      // print('[ListHandler] Source type: ${source.runtimeType}');

      // Unwrap ListWrapper
      if (source is ListWrapper) source = source.toList();

      if (source is Iterable) {
        final mappedItems = source.map((item) {
          final itemContext = Map<String, dynamic>.from(context);

          // WRAP THE ITEM
          if (item is FormalParameter) {
            itemContext['item'] = ParameterWrapper(item);
          } else if (item is DartType) {
            itemContext['item'] = TypeWrapper(item);
          } else {
            itemContext['item'] = item;
          }

          final itemResult = <String, dynamic>{};
          config.mapSchema.forEach((key, subConfig) {
            final cleanKey = key.startsWith('.') ? key.substring(1) : key;
            itemResult[cleanKey] = resolver.resolveConfig(subConfig, itemContext);
          });
          return itemResult;
        });
        result.addAll(mappedItems);
      } else {
        // print('[ListHandler] WARNING: Source is not Iterable! Value: "$source"');
      }
    }

    // B. Explicit Values
    if (config.values.isNotEmpty) {
      result.addAll(config.values.map((e) => engine.evaluate(e, context)));
    }

    // C. Spread
    if (config.spread.isNotEmpty) {
      for (final expr in config.spread) {
        final val = engine.evaluate(expr, context);
        if (val is Iterable) {
          result.addAll(val);
        } else {
          result.add(val);
        }
      }
    }

    return result;
  }
}
