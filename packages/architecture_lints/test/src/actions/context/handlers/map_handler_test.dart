import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/handlers/map_handler.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('MapHandler', () {
    late MapHandler handler;
    late VariableResolver resolver;

    setUp(() async {
      final unit = await resolveContent('class A {}');
      final node = unit.unit.declarations.first;
      final config = ArchitectureConfig.empty();
      final engine = ExpressionEngine(node: node, config: config);

      handler = MapHandler(engine);
      resolver = VariableResolver(sourceNode: node, config: config, packageName: 'test');
    });

    test('should handle explicit value map', () {
      const config = VariableConfig(
        type: VariableType.map,
        // The value property in config is a string expression.
        // We simulate an expression that returns a Map.
        value: 'myMap',
      );

      final context = {
        'myMap': {'key': 'value'},
      };

      final result = handler.handle(config, context, resolver) as Map;
      expect(result['key'], 'value');
    });

    test('should merge maps via spread', () {
      const config = VariableConfig(
        type: VariableType.map,
        spread: ['map1', 'map2'],
      );

      final context = {
        'map1': {'a': 1, 'b': 2},
        'map2': {'b': 99, 'c': 3}, // 'b' overrides map1
      };

      final result = handler.handle(config, context, resolver) as Map;

      expect(result['a'], 1);
      expect(result['b'], 99); // Last one wins
      expect(result['c'], 3);
    });
  });
}
