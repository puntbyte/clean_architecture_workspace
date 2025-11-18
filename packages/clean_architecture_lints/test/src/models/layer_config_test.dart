// test/src/models/layer_config_test.dart

import 'package:clean_architecture_lints/src/models/layer_config.dart';
import 'package:test/test.dart';

void main() {
  group('DomainLayerRule', () {
    group('fromMap', () {
      test('should parse valid configuration', () {
        final map = {
          'entity': ['entities', 'models'],
          'contract': ['contracts'],
          'usecase': ['usecases', 'interactors'],
        };

        final rule = DomainLayerRule.fromMap(map);

        expect(rule, isNotNull);
        expect(rule.entity, ['entities', 'models']);
        expect(rule.contract, ['contracts']);
        expect(rule.usecase, ['usecases', 'interactors']);
      });

      test('should use defaults when keys are missing', () {
        final map = <String, dynamic>{};
        final rule = DomainLayerRule.fromMap(map);

        expect(rule.entity, ['entities']);
        expect(rule.contract, ['contracts']);
        expect(rule.usecase, ['usecases']);
      });

      test('should handle single string values', () {
        final map = {
          'entity': 'custom_entity',
          'contract': 'custom_contract',
          'usecase': 'custom_usecase',
        };
        final rule = DomainLayerRule.fromMap(map);

        expect(rule.entity, ['custom_entity']);
        expect(rule.contract, ['custom_contract']);
        expect(rule.usecase, ['custom_usecase']);
      });

      test('should handle mixed single and list values', () {
        final map = {
          'entity': ['entities', 'models'],
          'contract': 'contracts',
          'usecase': ['usecases'],
        };
        final rule = DomainLayerRule.fromMap(map);

        expect(rule.entity, ['entities', 'models']);
        expect(rule.contract, ['contracts']);
        expect(rule.usecase, ['usecases']);
      });

      test('should ignore null values and use defaults', () {
        final map = <String, dynamic>{
          'entity': null,
          'contract': ['contracts'],
          'usecase': null,
        };
        final rule = DomainLayerRule.fromMap(map);

        expect(rule.entity, ['entities']); // default
        expect(rule.contract, ['contracts']);
        expect(rule.usecase, ['usecases']); // default
      });
    });
  });

  group('DataLayerRule', () {
    group('fromMap', () {
      test('should parse valid configuration', () {
        final map = {
          'model': ['models'],
          'repository': ['repos', 'repositories'],
          'source': ['sources', 'datasources'],
        };

        final rule = DataLayerRule.fromMap(map);

        expect(rule, isNotNull);
        expect(rule.model, ['models']);
        expect(rule.repository, ['repos', 'repositories']);
        expect(rule.source, ['sources', 'datasources']);
      });

      test('should use defaults when keys are missing', () {
        final map = <String, dynamic>{};
        final rule = DataLayerRule.fromMap(map);

        expect(rule.model, ['models']);
        expect(rule.repository, ['repositories']);
        expect(rule.source, ['sources']);
      });

      test('should handle single string values', () {
        final map = {
          'model': 'custom_model',
          'repository': 'custom_repo',
          'source': 'custom_source',
        };
        final rule = DataLayerRule.fromMap(map);

        expect(rule.model, ['custom_model']);
        expect(rule.repository, ['custom_repo']);
        expect(rule.source, ['custom_source']);
      });
    });
  });

  group('PresentationLayerRule', () {
    group('fromMap', () {
      test('should parse valid configuration', () {
        final map = {
          'page': ['pages', 'screens'],
          'widget': ['widgets', 'components'],
          'manager': ['managers', 'bloc', 'cubit'],
        };

        final rule = PresentationLayerRule.fromMap(map);

        expect(rule, isNotNull);
        expect(rule.page, ['pages', 'screens']);
        expect(rule.widget, ['widgets', 'components']);
        expect(rule.manager, ['managers', 'bloc', 'cubit']);
      });

      test('should use defaults when keys are missing', () {
        final map = <String, dynamic>{};
        final rule = PresentationLayerRule.fromMap(map);

        expect(rule.page, ['pages']);
        expect(rule.widget, ['widgets']);
        expect(rule.manager, ['managers']);
      });

      test('should handle single string values', () {
        final map = {
          'page': 'screens',
          'widget': 'components',
          'manager': 'controllers',
        };
        final rule = PresentationLayerRule.fromMap(map);

        expect(rule.page, ['screens']);
        expect(rule.widget, ['components']);
        expect(rule.manager, ['controllers']);
      });
    });
  });

  group('LayerConfig', () {
    group('fromMap', () {
      test('should create instance with all rule types', () {
        final map = {
          'domain': {'entity': ['entities']},
          'data': {'model': ['models']},
          'presentation': {'page': ['pages']},
        };

        final config = LayerConfig.fromMap(map);

        expect(config, isA<LayerConfig>());
        expect(config.domain, isA<DomainLayerRule>());
        expect(config.data, isA<DataLayerRule>());
        expect(config.presentation, isA<PresentationLayerRule>());
      });

      test('should use default rules when maps are empty', () {
        final map = {
          'domain': <String, dynamic>{},
          'data': <String, dynamic>{},
          'presentation': <String, dynamic>{},
        };

        final config = LayerConfig.fromMap(map);

        expect(config.domain.entity, ['entities']);
        expect(config.data.model, ['models']);
        expect(config.presentation.page, ['pages']);
      });

      test('should handle missing keys by using defaults', () {
        final config = LayerConfig.fromMap({});

        expect(config.domain.entity, ['entities']);
        expect(config.data.model, ['models']);
        expect(config.presentation.page, ['pages']);
      });

      test('should parse real-world configuration structure', () {
        final map = {
          'domain': {
            'entity': 'entities',
            'contract': 'contracts',
            'usecase': 'usecases',
          },
          'data': {
            'model': 'models',
            'repository': 'repositories',
            'source': 'sources',
          },
          'presentation': {
            'page': 'pages',
            'widget': 'widgets',
            'manager': ['managers', 'bloc', 'cubit'],
          },
        };

        final config = LayerConfig.fromMap(map);

        expect(config.domain.entity, ['entities']);
        expect(config.domain.contract, ['contracts']);
        expect(config.domain.usecase, ['usecases']);
        expect(config.data.model, ['models']);
        expect(config.data.repository, ['repositories']);
        expect(config.data.source, ['sources']);
        expect(config.presentation.page, ['pages']);
        expect(config.presentation.widget, ['widgets']);
        expect(config.presentation.manager, ['managers', 'bloc', 'cubit']);
      });
    });
  });
}
