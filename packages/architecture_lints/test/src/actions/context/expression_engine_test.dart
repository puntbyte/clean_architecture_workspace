import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/expression_engine.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:test/test.dart';

import '../../../helpers/test_resolver.dart';

void main() {
  group('ExpressionEngine', () {
    late ExpressionEngine engine;
    late ArchitectureConfig mockConfig;

    setUp(() async {
      // 1. Setup Source
      const code = '''
        class Auth { 
          void login(String username) {} 
        }
      ''';
      final unit = await resolveContent(code);

      final clazz = unit.unit.declarations.whereType<ClassDeclaration>().first;
      final method = clazz.members.whereType<MethodDeclaration>().first;

      // 2. Setup Config
      mockConfig = const ArchitectureConfig(
        components: [],
        definitions: {
          'core.base': Definition(types: ['BaseClass']),
        },
      );

      // 3. Initialize Engine
      engine = ExpressionEngine(node: method, config: mockConfig);
    });

    group('evaluate()', () {
      test('should evaluate raw expressions using MemberAccessors', () {
        // source (MethodWrapper) -> name (StringWrapper) -> pascalCase (String)
        final result = engine.evaluate('source.name.pascalCase', {});
        expect(result, 'Login');
      });

      test('should evaluate string interpolation', () {
        final result = engine.evaluate(r'Use case: ${source.name.snakeCase}.dart', {});
        expect(result, 'Use case: login.dart');
      });

      test('should access definitions via config.definitionFor', () {
        // FIX: Use config.definitionFor() which returns a Map
        // definitions['...'] would return a Definition object which has no accessor now.
        final result = engine.evaluate("config.definitionFor('core.base').type", {});
        expect(result, 'BaseClass');
      });

      test('should fallback to raw string on error', () {
        const input = 'missing.property';
        final result = engine.evaluate(input, {});
        expect(result, input);
      });

      test('should use passed context over root context', () {
        final result = engine.evaluate('custom.pascalCase', {
          'custom': const StringWrapper('hello_world')
        });
        expect(result, 'HelloWorld');
      });
    });

    group('unwrap()', () {
      test('should unwrap StringWrapper to primitive String', () {
        const wrapper = StringWrapper('test');
        expect(engine.unwrap(wrapper), 'test');
      });

      test('should unwrap Definition to Map', () {
        const def = Definition(types: ['MyType']);
        final result = engine.unwrap(def);

        expect(result, isA<Map>());
        expect(result['type'], 'MyType');
      });

      test('should unwrap List of Wrappers to List of Primitives', () {
        final list = [const StringWrapper('a'), const StringWrapper('b')];
        final result = engine.unwrap(list);

        expect(result, isA<List>());
        expect(result, ['a', 'b']);
      });

      test('should unwrap Map values recursively', () {
        final map = {
          'key': const StringWrapper('value'),
          'nested': {'inner': const StringWrapper('innerValue')}
        };

        final result = engine.unwrap(map) as Map;

        expect(result['key'], 'value');
        expect((result['nested'] as Map)['inner'], 'innerValue');
      });
    });
  });
}
