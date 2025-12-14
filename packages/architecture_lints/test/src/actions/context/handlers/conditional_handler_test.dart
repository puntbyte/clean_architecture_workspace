import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/handlers/conditional_handler.dart';
import 'package:architecture_lints/src/config/enums/variable_type.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/variable_config.dart';
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

void main() {
  group('ConditionalHandler', () {
    late ExpressionEngine engine;
    late ConditionalHandler handler;

    setUp(() async {
      const code = 'class A { void method(int x) {} }';
      final unit = await resolveContent(code);
      final method = unit.unit.declarations.first.childEntities
          .whereType<MethodDeclaration>()
          .first;

      engine = ExpressionEngine(
        node: method,
        config: ArchitectureConfig.empty(),
      );
      handler = ConditionalHandler(engine);
    });

    test('should return first matching branch (if)', () {
      final select = [
        const VariableSelect(
          condition: 'true',
          result: VariableConfig(type: VariableType.string, value: "'A'"),
        ),
        const VariableSelect(
          result: VariableConfig(type: VariableType.string, value: "'B'"),
        ),
      ];

      final result = handler.handle(select, {});
      expect(result?.value, "'A'");
    });

    test('should fall through to else if condition is false', () {
      final select = [
        const VariableSelect(
          condition: 'false',
          result: VariableConfig(type: VariableType.string, value: "'A'"),
        ),
        const VariableSelect(
          result: VariableConfig(type: VariableType.string, value: "'B'"),
        ),
      ];

      final result = handler.handle(select, {});
      expect(result?.value, "'B'");
    });

    test('should evaluate expression against context', () {
      final select = [
        const VariableSelect(
          condition: 'myVar > 10',
          result: VariableConfig(type: VariableType.string, value: "'BIG'"),
        ),
        const VariableSelect(
          result: VariableConfig(type: VariableType.string, value: "'SMALL'"),
        ),
      ];

      // Context: myVar = 20
      final result1 = handler.handle(select, {'myVar': 20});
      expect(result1?.value, "'BIG'");

      // Context: myVar = 5
      final result2 = handler.handle(select, {'myVar': 5});
      expect(result2?.value, "'SMALL'");
    });

    test('should return null if no branch matches', () {
      final select = [
        const VariableSelect(
          condition: 'false',
          result: VariableConfig(type: VariableType.string, value: "'A'"),
        ),
        // No else branch
      ];

      final result = handler.handle(select, {});
      expect(result, isNull);
    });
  });
}
