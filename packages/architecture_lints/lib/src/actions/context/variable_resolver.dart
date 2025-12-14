import 'package:analyzer/dart/ast/ast.dart' hide Expression;
import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/handlers/conditional_handler.dart';
import 'package:architecture_lints/src/actions/context/handlers/list_handler.dart';
import 'package:architecture_lints/src/actions/context/handlers/map_handler.dart';
import 'package:architecture_lints/src/actions/context/handlers/set_handler.dart';
import 'package:architecture_lints/src/actions/context/helpers/import_extractor.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';

class VariableResolver {
  final ExpressionEngine _engine;
  final ConditionalHandler _conditionalHandler;
  final ListHandler _listHandler;
  final SetHandler _setHandler;
  final MapHandler _mapHandler;
  final ImportExtractor _importExtractor;

  VariableResolver({
    required AstNode sourceNode,
    required ArchitectureConfig config,
    required String packageName,
  }) : _engine = ExpressionEngine(node: sourceNode, config: config),
       _importExtractor = ImportExtractor(packageName, rewrites: config.importRewrites),
       _conditionalHandler = ConditionalHandler(
         ExpressionEngine(node: sourceNode, config: config),
       ),
       _listHandler = ListHandler(
         ExpressionEngine(node: sourceNode, config: config),
       ),
       _setHandler = SetHandler(
         ExpressionEngine(node: sourceNode, config: config),
       ),
       _mapHandler = MapHandler(
         ExpressionEngine(node: sourceNode, config: config),
       );

  Map<String, dynamic> resolveMap(Map<String, dynamic> variablesConfig) {
    final result = <String, dynamic>{};

    variablesConfig.forEach((key, value) {
      dynamic resolvedValue;

      if (value is String) {
        resolvedValue = _engine.evaluate(value, result);
      } else if (value is VariableConfig) {
        resolvedValue = resolveConfig(value, result);
      } else if (value is Map<String, dynamic> && !key.startsWith('.')) {
        resolvedValue = resolveMap(value);
      }

      result[key] = resolvedValue;
    });

    if (!result.containsKey('source')) {
      result['source'] = _engine.unwrap(_engine.rootContext['source']);
    }

    return result;
  }

  dynamic resolve(String expression) => _engine.evaluate(expression, {});

  dynamic resolveConfig(VariableConfig config, Map<String, dynamic> context) {
    if (config.select.isNotEmpty) {
      final selectedConfig = _conditionalHandler.handle(config.select, context);
      if (selectedConfig != null) return resolveConfig(selectedConfig, context);
      return null;
    }

    dynamic result = switch (config.type) {
      VariableType.list => _listHandler.handle(config, context, this),
      VariableType.set => _setHandler.handle(config, context, this),
      VariableType.map => _mapHandler.handle(config, context, this),
      _ when config.value != null => _engine.evaluate(config.value!, context),
      _ => null,
    };

    // 2. Apply Transformer (e.g. 'imports')
    if (config.transformer == 'imports' && result is Iterable) {
      final extracted = <String>{};
      _importExtractor.extract(result, extracted);
      result = extracted.toList()..sort();
    }

    // 3. Wrap Collections with Metadata
    if (result is Iterable && result is! Map) result = _buildCollectionMeta(result);

    // 4. Handle Nested Children
    if (config.children.isNotEmpty) {
      Map<String, dynamic> resultMap;

      if (result is Map<String, dynamic>) {
        resultMap = result;
      } else {
        resultMap = {};
        if (result != null) resultMap['value'] = result;
      }

      config.children.forEach(
        (childKey, childConfig) => resultMap[childKey] = resolveConfig(childConfig, context),
      );

      return _engine.unwrap(resultMap);
    }

    return _engine.unwrap(result);
  }

  Map<String, dynamic> _buildCollectionMeta(Iterable items) {
    final list = items.toList();
    return {
      'items': list,
      'length': list.length,
      'isEmpty': list.isEmpty,
      'isNotEmpty': list.isNotEmpty,
      'hasMany': list.length > 1,
      'isSingle': list.length == 1,
    };
  }
}
