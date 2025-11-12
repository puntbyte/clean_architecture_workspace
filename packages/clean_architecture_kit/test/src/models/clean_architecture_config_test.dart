// test/src/models/clean_architecture_config_test.dart

import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CleanArchitectureConfig', () {
    group('fromMap factory', () {
      test('should create a valid config from a complete map with custom values', () {
        // This map simulates a rich, user-customized analysis_options.yaml file.
        final map = <String, dynamic>{
          'project_structure': 'layer_first',
          'layer_definitions': {
            'domain': {'entities': ['domain/entities_v2']}
          },
          'naming_conventions': {
            'model': '{{name}}Dto',
            'entity': {
              'pattern': '{{name}}',
              'anti_pattern': ['{{name}}Entity'],
            }
          },
          'inheritance': {
            'entity_base_name': 'BaseDomainObject',
          },
          'type_safety': {
            'returns': [
              {'type': 'FutureResult', 'where': ['useCase']}
            ],
          },
          'services': {
            'dependency_injection': {
              'service_locator_names': ['diContainer', 'get'],
              'use_case_annotations': [
                {'annotation_text': '@Singleton()'}
              ],
            }
          },
        };

        final config = CleanArchitectureConfig.fromMap(map);

        // --- Assertions ---
        // Verify that the nested parsers were called and assigned the correct values.
        expect(config, isA<CleanArchitectureConfig>());

        // Check LayerConfig
        expect(config.layers.projectStructure, 'layer_first');
        expect(config.layers.domainEntitiesPaths, ['domain/entities_v2']);

        // Check NamingConfig
        expect(config.naming.model.pattern, '{{name}}Dto');
        expect(config.naming.entity.antipatterns, ['{{name}}Entity']);

        // Check InheritanceConfig
        expect(config.inheritance.entityBaseName, 'BaseDomainObject');

        // Check TypeSafetyConfig
        expect(config.typeSafety.returns, isNotEmpty);
        expect(config.typeSafety.returns.first.type, 'FutureResult');
        expect(config.typeSafety.parameters, isEmpty);

        // Check ServicesConfig and its nested DI config
        expect(config.services.dependencyInjection.serviceLocatorNames, ['diContainer', 'get']);
        expect(config.services.dependencyInjection.useCaseAnnotations, isNotEmpty);
        expect(config.services.dependencyInjection.useCaseAnnotations.first.annotationText, '@Singleton()');
      });

      test('should create a valid config with all defaults from an empty map', () {
        // This test ensures that a minimal user config is valid and populates all defaults.
        final map = <String, dynamic>{};
        final config = CleanArchitectureConfig.fromMap(map);

        // --- Assertions ---
        // Verify that default values from all child configs are present.
        expect(config, isA<CleanArchitectureConfig>());

        // Check LayerConfig defaults
        expect(config.layers.projectStructure, 'feature_first');
        expect(config.layers.domainRepositoriesPaths, ['contracts']);

        // Check NamingConfig defaults
        expect(config.naming.model.pattern, '{{name}}Model');
        expect(config.naming.entity.antipatterns, isEmpty);

        // Check InheritanceConfig defaults
        expect(config.inheritance.repositoryBaseName, 'Repository');

        // Check TypeSafetyConfig defaults
        expect(config.typeSafety.returns, isEmpty);
        expect(config.typeSafety.parameters, isEmpty);

        // Check ServicesConfig defaults
        expect(config.services.dependencyInjection.serviceLocatorNames, contains('getIt'));
        expect(config.services.dependencyInjection.useCaseAnnotations, isEmpty);
      });

      // NEW TEST: ensure LayerResolver resolves a feature_first repository path to domainRepository
      test('LayerResolver resolves domainRepository for feature_first path', () {
        // Build a feature-first config similar to your analysis_options example.
        final map = <String, dynamic>{
          'project_structure': 'feature_first',
          'feature_first_paths': {'features_root': 'features'},
          'layer_definitions': {
            'domain': {
              'repositories': ['contracts'],
              'usecases': ['usecases'],
            }
          },
        };
        final config = CleanArchitectureConfig.fromMap(map);
        final resolver = LayerResolver(config);

        // Example path from your repo:
        final examplePath = p.join('lib', 'features', 'auth', 'domain', 'contracts', 'contracts.violations.dart');

        final sub = resolver.getSubLayer(examplePath);
        expect(sub, ArchSubLayer.domainRepository);
      });
    });
  });
}
