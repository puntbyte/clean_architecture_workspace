// test/src/models/module_config_test.dart

import 'package:clean_architecture_lints/src/models/module_config.dart';
import 'package:clean_architecture_lints/src/utils/config_keys.dart';
import 'package:test/test.dart';

void main() {
  group('ModuleType', () {
    group('parse', () {
      test('should parse layer_first to ModuleType.layerFirst', () {
        expect(ModuleType.fromString('layer_first'), ModuleType.layerFirst);
      });

      test('should parse feature_first to ModuleType.featureFirst', () {
        expect(ModuleType.fromString('feature_first'), ModuleType.featureFirst);
      });

      test('should return unknown for invalid string', () {
        expect(ModuleType.fromString('invalid'), ModuleType.unknown);
      });

      test('should return unknown for empty string', () {
        expect(ModuleType.fromString(''), ModuleType.unknown);
      });

      test('should be case-sensitive', () {
        expect(ModuleType.fromString('Layer_First'), ModuleType.unknown);
        expect(ModuleType.fromString('Feature_First'), ModuleType.unknown);
      });
    });
  });

  group('ModuleConfig', () {
    group('fromMap', () {
      test('should parse complete configuration with layer_first', () {
        final map = {
          ConfigKey.module.type: 'layer_first',
          ConfigKey.module.core: 'core',
          ConfigKey.module.features: 'features',
          ConfigKey.module.layers: {
            ConfigKey.module.domain: 'domain',
            ConfigKey.module.data: 'data',
            ConfigKey.module.presentation: 'presentation',
          },
        };

        final config = ModuleConfig.fromMap(map);

        expect(config.type, ModuleType.layerFirst);
        expect(config.core, 'core');
        expect(config.features, 'features');
        expect(config.domain, 'domain');
        expect(config.data, 'data');
        expect(config.presentation, 'presentation');
      });

      test('should parse complete configuration with feature_first', () {
        final map = {
          ConfigKey.module.type: 'feature_first',
          ConfigKey.module.core: 'my_core',
          ConfigKey.module.features: 'my_features',
          ConfigKey.module.layers: {
            ConfigKey.module.domain: 'my_domain',
            ConfigKey.module.data: 'my_data',
            ConfigKey.module.presentation: 'my_presentation',
          },
        };

        final config = ModuleConfig.fromMap(map);

        expect(config.type, ModuleType.featureFirst);
        expect(config.core, 'my_core');
        expect(config.features, 'my_features');
        expect(config.domain, 'my_domain');
        expect(config.data, 'my_data');
        expect(config.presentation, 'my_presentation');
      });

      test('should use defaults when keys are missing', () {
        final map = <String, dynamic>{};
        final config = ModuleConfig.fromMap(map);

        expect(config.type, ModuleType.featureFirst);
        expect(config.core, 'core');
        expect(config.features, 'features');
        expect(config.domain, 'domain');
        expect(config.data, 'data');
        expect(config.presentation, 'presentation');
      });

      test('should use defaults for missing nested layer keys', () {
        final map = {
          ConfigKey.module.type: 'feature_first',
          ConfigKey.module.layers: {
            ConfigKey.module.domain: 'custom_domain',
          },
        };
        final config = ModuleConfig.fromMap(map);

        expect(config.domain, 'custom_domain');
        expect(config.data, 'data');
        expect(config.presentation, 'presentation');
      });

      test('should handle null values gracefully', () {
        final map = {
          ConfigKey.module.type: null,
          ConfigKey.module.core: null,
          ConfigKey.module.features: null,
          ConfigKey.module.layers: null,
        };
        final config = ModuleConfig.fromMap(map);

        expect(config.type, ModuleType.featureFirst);
        expect(config.core, 'core');
        expect(config.features, 'features');
        expect(config.domain, 'domain');
        expect(config.data, 'data');
        expect(config.presentation, 'presentation');
      });

      test('should handle unknown module type gracefully', () {
        final map = {
          ConfigKey.module.type: 'invalid_type',
        };
        final config = ModuleConfig.fromMap(map);

        expect(config.type, ModuleType.unknown);
      });

      test('should handle empty layers map', () {
        final map = {
          ConfigKey.module.type: 'layer_first',
          ConfigKey.module.layers: <String, dynamic>{},
        };
        final config = ModuleConfig.fromMap(map);

        expect(config.domain, 'domain');
        expect(config.data, 'data');
        expect(config.presentation, 'presentation');
      });

      test('should preserve custom layer paths', () {
        final map = {
          ConfigKey.module.layers: {
            ConfigKey.module.domain: 'lib/src/domain',
            ConfigKey.module.data: 'lib/src/data',
            ConfigKey.module.presentation: 'lib/src/presentation',
          },
        };
        final config = ModuleConfig.fromMap(map);

        expect(config.domain, 'lib/src/domain');
        expect(config.data, 'lib/src/data');
        expect(config.presentation, 'lib/src/presentation');
      });

      test('should handle non-string values by using defaults', () {
        final map = {
          ConfigKey.module.core: 123,
          ConfigKey.module.features: true,
          ConfigKey.module.layers: {
            ConfigKey.module.domain: null,
          },
        };
        final config = ModuleConfig.fromMap(map);

        expect(config.core, 'core');
        expect(config.features, 'features');
        expect(config.domain, 'domain');
      });

      test('should be used as a const constructor', () {
        const config = ModuleConfig(
          type: ModuleType.featureFirst,
          core: 'core',
          features: 'features',
          domain: 'domain',
          data: 'data',
          presentation: 'presentation',
        );

        expect(config.type, ModuleType.featureFirst);
        expect(config.core, 'core');
      });
    });
  });
}
