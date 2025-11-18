// test/src/models/architecture_config_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/models/module_config.dart';
import 'package:test/test.dart';

void main() {
  group('ArchitectureConfig', () {
    group('fromMap Factory', () {
      test('should correctly parse a complete and valid configuration', () {
        final completeConfigMap = _createCompleteConfig();
        final config = ArchitectureConfig.fromMap(completeConfigMap);
        _verifyCompleteConfig(config);
      });

      test('should use sensible defaults when the configuration map is empty', () {
        final config = ArchitectureConfig.fromMap({});
        _verifyDefaultConfig(config);
      });

      test('should handle null values for configuration blocks by using defaults', () {
        final config = ArchitectureConfig.fromMap({
          'module_definitions': null,
          'layer_definitions': null,
          'naming_conventions': null,
          'type_safeties': null,
          'inheritances': null,
          'annotations': null,
          'services': null,
        });
        _verifyDefaultConfig(config);
      });

      test('should parse partial configurations gracefully, applying defaults for missing parts', () {
        final partialConfig = {
          'module_definitions': {
            'type': 'layer_first',
            'features': 'my_features',
          },
        };
        final config = ArchitectureConfig.fromMap(partialConfig);

        // Verify specified values
        expect(config.module.type, ModuleType.layerFirst);
        expect(config.module.features, 'my_features');

        // Verify defaults for unspecified values
        expect(config.module.core, 'core'); // Default
        expect(config.typeSafeties.rules, isEmpty);
        expect(config.inheritances.rules, isEmpty);
        expect(config.annotations.rules, isEmpty);
      });
    });

    group('AnnotationsConfig Delegation', () {
      late ArchitectureConfig config;

      setUp(() {
        config = ArchitectureConfig.fromMap({
          'annotations': [
            {
              'on': ['usecase'],
              'required': {'name': 'Injectable'},
            },
          ],
        });
      });

      test('ruleFor should find and return the correct annotation rule for a component', () {
        final rule = config.annotations.ruleFor('usecase');
        expect(rule, isNotNull);
        expect(rule!.on, contains('usecase'));
        expect(rule.required.first.name, 'Injectable');
      });

      test('requiredFor should return the list of required annotations for a component', () {
        final requiredAnnotations = config.annotations.requiredFor('usecase');
        expect(requiredAnnotations, hasLength(1));
        expect(requiredAnnotations.first.name, 'Injectable');
      });
    });
  });
}

// Helper Functions for Configuration and Verification

Map<String, dynamic> _createCompleteConfig() {
  return {
    'module_definitions': {
      'type': 'feature_first',
      'core': 'core_module',
      'features': 'features_module',
      'layers': {
        'domain': 'domain_layer',
        'data': 'data_layer',
        'presentation': 'presentation_layer',
      },
    },
    'layer_definitions': {
      'domain': {
        'entity': 'entities_dir',
        'contract': 'contracts_dir',
        'usecase': 'usecases_dir',
      },
      'data': {
        'model': 'models_dir',
        'repository': 'repositories_dir',
        'source': 'sources_dir',
      },
      'presentation': {
        'page': 'pages_dir',
        'widget': 'widgets_dir',
        'manager': ['managers_dir', 'bloc', 'cubit'],
      },
    },
    'naming_conventions': [
      {
        'on': 'entity',
        'pattern': '{{name}}',
        'antipattern': '{{name}}Entity',
      },
      {
        'on': 'model',
        'pattern': '{{name}}Model',
        'grammar': '{{noun.phrase}}Model',
      },
    ],
    'type_safeties': [
      {
        'on': ['usecase', 'contract'],
        'returns': {
          'unsafe_type': 'Future',
          'safe_type': 'FutureEither',
          'import': 'package:example/core/utils/types.dart',
        },
      },
      {
        'on': 'contract',
        'parameters': [
          {
            'identifier': 'id',
            'unsafe_type': 'int',
            'safe_type': 'IntId',
            'import': 'package:example/core/utils/types.dart',
          }
        ],
      },
    ],
    'inheritances': [
      {
        'on': 'entity',
        'required': {
          'name': 'Entity',
          'import': 'package:example/core/entity/entity.dart',
        },
      },
    ],
    'annotations': [
      {
        'on': ['usecase'],
        'required': {'name': 'Injectable'},
        'forbidden': {
          'name': ['LazySingleton'],
        },
      },
      {
        'on': ['model'],
        'allowed': [
          {'name': 'freezed'},
          {'name': 'MappableClass'},
        ],
      },
    ],
    'services': {
      'service_locator': {
        'name': ['getIt', 'locator', 'sl'],
      },
    },
  };
}

void _verifyCompleteConfig(ArchitectureConfig config) {
  _verifyModuleConfig(config);
  _verifyLayerConfig(config);
  _verifyNamingConfig(config);
  _verifyTypeSafetyConfig(config);
  _verifyInheritanceConfig(config);
  _verifyAnnotationsConfig(config);
  _verifyServicesConfig(config);
}

void _verifyModuleConfig(ArchitectureConfig config) {
  expect(config.module.type, ModuleType.featureFirst);
  expect(config.module.core, 'core_module');
  expect(config.module.features, 'features_module');
  expect(config.module.domain, 'domain_layer');
  expect(config.module.data, 'data_layer');
  expect(config.module.presentation, 'presentation_layer');
}

void _verifyLayerConfig(ArchitectureConfig config) {
  expect(config.layer.domain.entity, ['entities_dir']);
  expect(config.layer.domain.contract, ['contracts_dir']);
  expect(config.layer.domain.usecase, ['usecases_dir']);
  expect(config.layer.data.model, ['models_dir']);
  expect(config.layer.data.repository, ['repositories_dir']);
  expect(config.layer.data.source, ['sources_dir']);
  expect(config.layer.presentation.page, ['pages_dir']);
  expect(config.layer.presentation.widget, ['widgets_dir']);
  expect(config.layer.presentation.manager, ['managers_dir', 'bloc', 'cubit']);
}

void _verifyNamingConfig(ArchitectureConfig config) {
  expect(config.namingConventions.rules, isNotEmpty);
  final entityRule = config.namingConventions.getRuleFor(ArchComponent.entity);
  final modelRule = config.namingConventions.getRuleFor(ArchComponent.model);
  expect(entityRule?.pattern, '{{name}}');
  expect(entityRule?.antipattern, '{{name}}Entity');
  expect(modelRule?.pattern, '{{name}}Model');
  expect(modelRule?.grammar, '{{noun.phrase}}Model');
}

void _verifyTypeSafetyConfig(ArchitectureConfig config) {
  expect(config.typeSafeties.rules, hasLength(2));
  final returnRule = config.typeSafeties.rules.first;
  final paramRule = config.typeSafeties.rules[1];
  expect(returnRule.on, ['usecase', 'contract']);
  expect(returnRule.returns.first.safeType, 'FutureEither');
  expect(paramRule.on, ['contract']);
  expect(paramRule.parameters.first.safeType, 'IntId');
  expect(paramRule.parameters.first.identifier, 'id');
}

void _verifyInheritanceConfig(ArchitectureConfig config) {
  expect(config.inheritances.rules, hasLength(1));
  final entityRule = config.inheritances.rules.first;
  expect(entityRule.on, 'entity');
  expect(entityRule.required.first.name, 'Entity');
}

void _verifyAnnotationsConfig(ArchitectureConfig config) {
  expect(config.annotations.rules, hasLength(2));
  final useCaseRule = config.annotations.ruleFor('usecase');
  final modelRule = config.annotations.ruleFor('model');
  expect(useCaseRule?.required.first.name, 'Injectable');
  expect(useCaseRule?.forbidden.first.name, 'LazySingleton');
  expect(modelRule?.allowed, hasLength(2));
  expect(modelRule?.allowed.any((d) => d.name == 'freezed'), isTrue);
}

void _verifyServicesConfig(ArchitectureConfig config) {
  expect(config.services.dependencyInjection.serviceLocatorNames, ['getIt', 'locator', 'sl']);
}

void _verifyDefaultConfig(ArchitectureConfig config) {
  // Module defaults
  expect(config.module.type, ModuleType.featureFirst);
  expect(config.module.core, 'core');
  expect(config.module.features, 'features');
  expect(config.module.domain, 'domain');
  expect(config.module.data, 'data');
  expect(config.module.presentation, 'presentation');

  // Layer defaults
  expect(config.layer.domain.entity, ['entities']);
  expect(config.layer.data.model, ['models']);
  expect(config.layer.presentation.manager, ['managers']);

  // Other configs default to empty rules
  expect(config.namingConventions.rules, isEmpty);
  expect(config.typeSafeties.rules, isEmpty);
  expect(config.inheritances.rules, isEmpty);
  expect(config.annotations.rules, isEmpty);

  // Services defaults
  expect(
    config.services.dependencyInjection.serviceLocatorNames,
    ['getIt', 'locator', 'sl'],
  );
}
