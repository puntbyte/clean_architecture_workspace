// test/src/models/configs/architecture_config_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/configs/architecture_config.dart';
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('ArchitectureConfig', () {
    group('Complete Configuration Parsing', () {
      late ArchitectureConfig config;

      setUp(() {
        config = makeConfig(
          // 1. Structure overrides
          coreDir: 'core_lib',
          featuresDir: 'feats',
          entityDir: 'entities',
          modelDir: ['dtos'],
          pageDir: 'screens',

          // 2. Inheritance overrides
          inheritances: [
            {
              'on': 'entity',
              'required': {'name': 'BaseEntity', 'import': 'pkg:core'},
            },
          ],

          // 3. Naming overrides
          namingRules: [
            {'on': 'model', 'pattern': '{{name}}Model'},
          ],

          // 4. Type Safety overrides
          typeSafeties: [
            {
              'on': ['port'],
              'forbidden': [
                {'kind': 'return', 'type': 'Future'},
              ],
            },
          ],

          // 5. Dependency overrides
          dependencies: [
            {
              'on': 'domain',
              'forbidden': {'package': 'flutter'},
            },
          ],

          // 6. Annotation overrides
          annotations: [
            {
              'on': 'usecase',
              'required': {'name': 'Injectable'},
            },
          ],

          // 7. Service overrides
          services: {
            'service_locator': {
              'name': ['getIt'],
            },
          },

          // 8. Type Definition overrides
          // FIX: Must be a List of Maps with a 'key' property to match TypesConfig parser
          typeDefinitions: {
            'result': [
              {'key': 'wrapper', 'name': 'FutureEither'},
            ],
          },

          // 9. Error Handler overrides
          errorHandlers: [
            {
              'on': 'repository',
              'role': 'boundary',
              'required': [
                {'operation': 'try_return'},
              ],
            },
          ],
        );
      });

      test('should parse module definitions correctly', () {
        expect(config.modules.core, 'core_lib');
        expect(config.modules.features, 'feats');
      });

      test('should parse layer definitions correctly', () {
        expect(config.layers.domain.entity, contains('entities'));
        expect(config.layers.data.model, contains('dtos'));
        expect(config.layers.presentation.page, contains('screens'));
      });

      test('should parse inheritance rules correctly', () {
        final rule = config.inheritances.ruleFor(ArchComponent.entity);
        expect(rule, isNotNull, reason: 'Entity inheritance rule should exist');
        expect(rule!.required.first.name, 'BaseEntity');
      });

      test('should parse naming convention rules correctly', () {
        final rule = config.namingConventions.ruleFor(ArchComponent.model);
        expect(rule, isNotNull, reason: 'Model naming rule should exist');
        expect(rule!.pattern, '{{name}}Model');
      });

      test('should parse type safety rules correctly', () {
        final rules = config.typeSafeties.rulesFor(ArchComponent.port);
        expect(rules, isNotEmpty, reason: 'Port type safety rules should exist');
        expect(rules.first.forbidden.first.type, 'Future');
      });

      test('should parse dependency rules correctly', () {
        final rule = config.dependencies.ruleFor(ArchComponent.domain);
        expect(rule, isNotNull, reason: 'Domain dependency rule should exist');
        expect(rule!.forbidden.packages, contains('flutter'));
      });

      test('should parse annotation rules correctly', () {
        final rule = config.annotations.ruleFor(ArchComponent.usecase);
        expect(rule, isNotNull, reason: 'Usecase annotation rule should exist');
        expect(rule!.required.first.name, 'Injectable');
      });

      test('should parse service locator rules correctly', () {
        expect(config.services.serviceLocator.names, contains('getIt'));
      });

      test('should parse type definitions correctly', () {
        final typeDef = config.typeDefinitions.get('result.wrapper');
        expect(typeDef, isNotNull, reason: 'result.wrapper type definition should exist');
        expect(typeDef!.name, 'FutureEither');
      });

      test('should parse error handler rules correctly', () {
        final rule = config.errorHandlers.ruleFor(ArchComponent.repository);
        expect(rule, isNotNull, reason: 'Repository error handler rule should exist');
        expect(rule!.required.first.operations, contains('try_return'));
      });
    });

    group('Default / Empty Configuration', () {
      test('should use defaults when config is empty (via makeConfig)', () {
        final config = makeConfig();

        expect(config.modules.core, 'core');
        expect(config.layers.domain.entity, contains('entities'));
        expect(config.services.serviceLocator.names, contains('getIt'));

        expect(config.inheritances.rules, isEmpty);
        expect(config.dependencies.rules, isEmpty);
        expect(config.errorHandlers.rules, isEmpty);
      });

      test('should handle raw empty map gracefully', () {
        final map = <String, dynamic>{};
        final config = ArchitectureConfig.fromMap(map);

        expect(config.modules.core, 'core');
        expect(config.typeDefinitions.get('any'), isNull);
        expect(config.errorHandlers.rules, isEmpty);
      });
    });
  });
}
