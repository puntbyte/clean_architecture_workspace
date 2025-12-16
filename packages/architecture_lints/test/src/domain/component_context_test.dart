// test/domain/component_context_test.dart

import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/context/module_context.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Mocks for the external types
class _MockComponentConfig extends Mock implements ComponentDefinition {}
class _MockModuleContext extends Mock implements ModuleContext {}

void main() {
  late _MockComponentConfig config;
  late _MockModuleContext module;
  const filePath = '/path/to/file.dart';

  setUp(() {
    config = _MockComponentConfig();
    module = _MockModuleContext();
  });

  group('ComponentContext getters', () {
    test('forwards displayName, patterns, antipatterns, grammar, and id', () {
      when(() => config.id).thenReturn('data.source.implementation');
      when(() => config.displayName).thenReturn('Source Implementation');
      when(() => config.patterns).thenReturn(['*.dart']);
      when(() => config.antipatterns).thenReturn(['test_*']);
      when(() => config.grammar).thenReturn(['snake_case']);

      final ctx = ComponentContext(filePath: filePath, definition: config, module: null);

      expect(ctx.id, equals('data.source.implementation'));
      expect(ctx.displayName, equals('Source Implementation'));
      expect(ctx.patterns, equals(['*.dart']));
      expect(ctx.antipatterns, equals(['test_*']));
      expect(ctx.grammar, equals(['snake_case']));
    });
  });

  group('matchesReference', () {
    test('returns true when module key matches referenceId', () {
      when(() => config.id).thenReturn('data.source.implementation');
      when(() => module.key).thenReturn('my-module-key');

      final ctx = ComponentContext(filePath: filePath, definition: config, module: module);

      expect(ctx.matchesReference('my-module-key'), isTrue);
    });

    test('returns true for exact id match', () {
      when(() => config.id).thenReturn('data.source.implementation');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      expect(ctx.matchesReference('data.source.implementation'), isTrue);
    });

    test('returns true for suffix (robust shorthand) match', () {
      // id: data.source.implementation
      // ref: source.implementation -> suffix match
      when(() => config.id).thenReturn('data.source.implementation');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      expect(ctx.matchesReference('source.implementation'), isTrue);
    });

    test('returns true for prefix match', () {
      // id: data.source.implementation
      // ref: data.source -> prefix match
      when(() => config.id).thenReturn('data.source.implementation');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      expect(ctx.matchesReference('data.source'), isTrue);
    });

    test('returns true for middle (slice) match', () {
      // id: a.b.c.d
      // ref: b.c -> middle match
      when(() => config.id).thenReturn('a.b.c.d');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      expect(ctx.matchesReference('b.c'), isTrue);
    });

    test('returns false when ref has more segments than id', () {
      // id: a.b
      // ref: x.y.z (longer) -> false early
      when(() => config.id).thenReturn('a.b');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      expect(ctx.matchesReference('x.y.z'), isFalse);
    });

    test('returns false when no contiguous match found', () {
      when(() => config.id).thenReturn('alpha.beta.gamma');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      expect(ctx.matchesReference('beta.gamma.delta'), isFalse);
      expect(ctx.matchesReference('zeta'), isFalse);
    });
  });

  group('matchesAny', () {
    test('returns true if any reference matches', () {
      when(() => config.id).thenReturn('data.source.implementation');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      expect(ctx.matchesAny(['no.match', 'source.implementation', 'other']), isTrue);
    });

    test('returns false if none match', () {
      when(() => config.id).thenReturn('data.source.implementation');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      expect(ctx.matchesAny(['no.match', 'another.one']), isFalse);
    });

    test('returns true when match appears later in a long list of references', () {
      when(() => config.id).thenReturn('a.b.c.d');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      // matching ref is near the end of the list
      final refs = [
        'x.y',
        'alpha.beta',
        'not.match',
        'b.c', // this should match (middle slice)
      ];

      expect(ctx.matchesAny(refs), isTrue);
    });

    test('handles duplicate and multiple matching reference ids', () {
      when(() => config.id).thenReturn('service.handler.impl');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      final refs = [
        'nope',
        'service.handler', // matches (prefix)
        'service.handler', // duplicate
        'handler.impl', // also matches (suffix)
      ];

      expect(ctx.matchesAny(refs), isTrue);
    });
  });


  group('toString', () {
    test('includes id and module name when module present', () {
      when(() => config.id).thenReturn('data.repo');
      when(() => module.name).thenReturn('Payments Module');

      final ctx = ComponentContext(filePath: filePath, definition: config, module: module);

      expect(ctx.toString(), contains('ComponentContext(id: data.repo'));
      expect(ctx.toString(), contains('module: Payments Module'));
    });

    test('shows module as null when module absent', () {
      when(() => config.id).thenReturn('data.repo');

      final ctx = ComponentContext(filePath: filePath, definition: config);

      expect(ctx.toString(), contains('ComponentContext(id: data.repo, module: null)'));
    });
  });
}
