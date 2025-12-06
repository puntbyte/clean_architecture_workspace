import 'package:architecture_lints/src/config/parsing/hierarchy_parser.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentParser', () {
    List<String> parseIds(
        Map<String, dynamic> yaml, [
          List<ModuleConfig> modules = const [],
        ]) {
      final results = HierarchyParser.parse(
        yaml: yaml,
        definedModules: modules,
      );
      return results.map((c) => c.id).toList();
    }

    test('should parse simple flat components', () {
      final yaml = {
        'flat_component': {'path': 'flat'},
        'another.flat': {'path': 'another'},
      };
      final ids = parseIds(yaml);
      expect(ids, containsAll(['flat_component', 'another.flat']));
    });

    test('should parse top-level components starting with dot', () {
      final yaml = {
        '.domain': {'path': 'domain'},
        '.data': {'path': 'data'},
      };
      final ids = parseIds(yaml);
      expect(ids, containsAll(['domain', 'data']));
    });

    test('should parse nested components recursively', () {
      final yaml = {
        '.domain': {
          'path': 'domain',
          '.entity': {
            'pattern': '{{name}}',
            '.field': {} // Was failing here
          },
          '.usecase': {} // Was failing here
        }
      };

      final ids = parseIds(yaml);

      expect(ids, containsAll([
        'domain',
        'domain.entity',
        'domain.entity.field',
        'domain.usecase',
      ]));
      expect(ids, isNot(contains('domain.path')));
    });

    test('should handle Module scoping correctly', () {
      final modules = [
        const ModuleConfig(key: 'core', path: 'core'),
        const ModuleConfig(key: 'shared', path: 'shared'),
      ];

      final yaml = {
        'core': {
          '.error': {'path': 'error'},
          '.util': {}
        },
        'shared': {
          '.widget': {}
        },
        'feature': {
          '.bloc': {}
        }
      };

      final ids = parseIds(yaml, modules);

      expect(ids, containsAll([
        'core',
        'core.error',
        'core.util',
        'shared',
        'shared.widget',
        'feature',
        'feature.bloc',
      ]));
    });

    test('should ignore properties inside nested objects', () {
      final yaml = {
        '.domain': {
          'path': 'domain',
          'map_prop': {
            'sub_key': 'value'
          },
          '.valid_child': {}
        }
      };

      final ids = parseIds(yaml);
      expect(ids, containsAll(['domain', 'domain.valid_child']));
      expect(ids.length, 2); // Should not include map_prop
    });
  });
}