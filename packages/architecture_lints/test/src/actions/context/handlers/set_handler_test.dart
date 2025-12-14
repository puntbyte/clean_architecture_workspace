import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/handlers/set_handler.dart';
import 'package:architecture_lints/src/actions/context/variable_resolver.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('SetHandler', () {
    late SetHandler handler;
    late VariableResolver resolver;

    setUp(() async {
      final unit = await resolveContent('class A {}');
      final node = unit.unit.declarations.first;
      final config = ArchitectureConfig.empty();

      final engine = ExpressionEngine(node: node, config: config);

      // SetHandler usually needs ImportExtractor for the resolver's context,
      // but the SetHandler logic itself just aggregates.
      // If we use transformer: 'imports', that happens in VariableResolver, not SetHandler.
      // SetHandler just builds the set.
      handler = SetHandler(engine);
      resolver = VariableResolver(sourceNode: node, config: config, packageName: 'test');
    });

    test('should deduplicate simple values', () {
      const config = VariableConfig(
        type: VariableType.set,
        values: ["'a'", "'b'", "'a'"], // 'a' repeated
      );

      final result = handler.handle(config, {}, resolver) as Set;
      expect(result, {'a', 'b'});
      expect(result.length, 2);
    });

    test('should flatten iterables from spread', () {
      const config = VariableConfig(
        type: VariableType.set,
        spread: ['list1', 'list2'],
      );

      final context = {
        'list1': ['a', 'b'],
        'list2': ['b', 'c'], // 'b' is duplicate across lists
      };

      final result = handler.handle(config, context, resolver) as Set;
      expect(result, {'a', 'b', 'c'});
    });
  });
}
