import 'package:architecture_lints/src/configuration/parsing/config_loader.dart';
import 'package:architecture_lints/src/configuration/project_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../../utils/architecture_config_mock.dart';

void main() {
  group('ConfigLoader', () {
    // Critical: Reset the static cache before every test to ensure isolation.
    setUp(ConfigLoader.reset);

    test('should return an empty config if the yaml contains no components', () {
      final yamlContent = ArchitectureConfigMock().toYaml();

      final config = ConfigLoaderExtension.parseString(yamlContent);

      expect(config.components, isEmpty);
    });

    test('should parse a single component with all fields defined', () {
      final yamlContent = ArchitectureConfigMock()
          .addComponent(
            'domain.entity',
            name: 'Entity',
            path: 'domain/entities',
            pattern: '{{name}}',
            antipattern: '{{name}}Entity',
            grammar: '{{noun}}',
          )
          .toYaml();

      final config = ConfigLoaderExtension.parseString(yamlContent);

      expect(config.components.length, 1);

      final component = config.components['domain.entity'];
      expect(component, isNotNull);
      expect(component?.id, 'domain.entity');
      expect(component?.name, 'Entity');
      // Use p.normalize to ensure this passes on Windows/Mac/Linux
      expect(component?.path, p.normalize('domain/entities'));
      expect(component?.pattern, '{{name}}');
      expect(component?.antipattern, '{{name}}Entity');
      expect(component?.grammar, '{{noun}}');
    });

    test('should normalize file paths based on the operating system', () {
      // Input uses Unix style forward slashes (standard in YAML)
      final yamlContent = ArchitectureConfigMock()
          .addComponent(
            'data.repository',
            path: 'data/repositories/impl',
          )
          .toYaml();

      final config = ConfigLoaderExtension.parseString(yamlContent);

      final component = config.components['data.repository'];

      // Verification:
      // On Windows, this expects 'data\repositories\impl'
      // On Mac/Linux, this expects 'data/repositories/impl'
      expect(component?.path, p.normalize('data/repositories/impl'));
    });

    test('should use the component ID as the default name if "name" is missing', () {
      final yamlContent = ArchitectureConfigMock()
          .addComponent(
            'domain.value_object',
            path: 'domain/values',
            // name is intentionally omitted
          )
          .toYaml();

      final config = ConfigLoaderExtension.parseString(yamlContent);

      final component = config.components['domain.value_object'];
      expect(component?.name, 'domain.value_object');
    });

    test('should return null properties for undefined optional fields', () {
      final yamlContent = ArchitectureConfigMock()
          .addComponent(
            'minimal',
            path: 'lib',
          )
          .toYaml();

      final config = ConfigLoaderExtension.parseString(yamlContent);

      final component = config.components['minimal'];
      expect(component?.pattern, isNull);
      expect(component?.antipattern, isNull);
      expect(component?.grammar, isNull);
    });

    test('should handle multiple components correctly', () {
      final yamlContent = ArchitectureConfigMock()
          .addComponent('layer.one', path: 'one')
          .addComponent('layer.two', path: 'two')
          .toYaml();

      final config = ConfigLoaderExtension.parseString(yamlContent);

      expect(config.components.length, 2);
      expect(config.components.containsKey('layer.one'), isTrue);
      expect(config.components.containsKey('layer.two'), isTrue);
    });

    test('should gracefully handle empty or malformed YAML strings', () {
      // Testing the extension helper's safety
      final config = ConfigLoaderExtension.parseString('');
      expect(config.components, isEmpty);

      final configJson = ConfigLoaderExtension.parseString('{}');
      expect(configJson.components, isEmpty);
    });
  });
}

// Helper Extension to expose the parser logic without relying on File I/O
extension ConfigLoaderExtension on ConfigLoader {
  static ProjectConfig parseString(String content) {
    if (content.trim().isEmpty) {
      return ConfigLoader.parseYaml(YamlMap());
    }

    final dynamic yaml = loadYaml(content);

    if (yaml is YamlMap) return ConfigLoader.parseYaml(yaml);

    // Fallback for empty/invalid yaml in tests
    return ConfigLoader.parseYaml(YamlMap());
  }
}
