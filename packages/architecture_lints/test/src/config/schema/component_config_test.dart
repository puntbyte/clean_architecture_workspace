import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:test/test.dart';

void main() {
  group('ComponentConfig', () {
    group('fromMap', () {
      test('should parse basic properties', () {
        final map = {
          'name': 'My Component',
          'default': true,
        };
        final config = ComponentConfig.fromMap('comp.id', map);

        expect(config.id, 'comp.id');
        expect(config.name, 'My Component');
        expect(config.isDefault, isTrue);
      });

      test('should parse lists correctly (path, pattern, etc)', () {
        final map = {
          'path': ['lib/a', 'lib/b'],
          'pattern': '{{name}}C',
          'grammar': ['{{noun}}'],
        };
        final config = ComponentConfig.fromMap('id', map);

        expect(config.paths, ['lib/a', 'lib/b']);
        expect(config.patterns, ['{{name}}C']); // Single string becomes list
        expect(config.grammar, ['{{noun}}']);
      });

      test('should handle missing optional fields', () {
        final config = ComponentConfig.fromMap('id', {});

        expect(config.paths, isEmpty);
        expect(config.patterns, isEmpty);
        expect(config.antipatterns, isEmpty);
        expect(config.isDefault, isFalse);
      });
    });

    group('displayName', () {
      test('should return name if provided', () {
        const config = ComponentConfig(id: 'a.b', name: 'Custom Name');
        expect(config.displayName, 'Custom Name');
      });

      test('should generate readable name from ID', () {
        const config = ComponentConfig(id: 'domain.use_case');
        // Logic: Split by dot, Capitalize first letter
        // domain -> Domain, use_case -> Use_case
        expect(config.displayName, 'Domain Use_case');
      });

      test('should handle empty segments in ID gracefully', () {
        const config = ComponentConfig(id: 'domain..entity');
        expect(config.displayName, 'Domain Entity');
      });
    });

    group('parseMap (Integration with HierarchyParser)', () {
      test('should flatten hierarchical config', () {
        final yaml = {
          '.domain': {
            'path': 'domain',
            '.entity': {
              'path': 'entities',
              'pattern': '{{name}}'
            }
          }
        };

        final modules = <ModuleConfig>[];
        final results = ComponentConfig.parseMap(yaml, modules);

        expect(results, hasLength(2));

        final domain = results.firstWhere((c) => c.id == 'domain');
        expect(domain.paths, ['domain']);

        final entity = results.firstWhere((c) => c.id == 'domain.entity');
        expect(entity.paths, ['entities']);
        expect(entity.patterns, ['{{name}}']);
      });

      test('should handle module scoping', () {
        final yaml = {
          'core': {
            '.util': {'path': 'utils'}
          }
        };

        final modules = [
          const ModuleConfig(key: 'core', path: 'core'),
        ];

        final results = ComponentConfig.parseMap(yaml, modules);

        // Should produce 'core.util' (implicit 'core' container is skipped by logic if empty properties,
        // or included if it matches criteria. HierarchyParser logic determines this).
        // Based on ComponentConfig.parseMap logic `shouldParseNode` returns false for empty `core` map wrapper
        // but true for `.util` which has `path`.

        final util = results.firstWhere((c) => c.id == 'core.util');
        expect(util.paths, ['utils']);
      });
    });
  });
}