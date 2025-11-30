// test/src/models/naming_conventions_config_test.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/configs/naming_conventions_config.dart';
import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:test/test.dart';

void main() {
  group('NamingRule', () {
    group('tryFromMap factory', () {
      test('should create rule successfully when all valid fields are provided', () {
        final map = {
          'on': ['entity'],
          'pattern': '{{name}}',
          'antipattern': '{{name}}Entity',
          'grammar': '{{noun}}',
        };
        final rule = NamingRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, ['entity']);
        expect(rule.pattern, '{{name}}');
        expect(rule.antipattern, '{{name}}Entity');
        expect(rule.grammar, '{{noun}}');
      });

      test('should default pattern to {{name}} when only grammar is provided', () {
        final map = {'on': ['usecase'], 'grammar': '{{verb}}{{noun}}'};
        final rule = NamingRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.pattern, '{{name}}');
        expect(rule.grammar, '{{verb}}{{noun}}');
      });

      test('should return null when `on` key is missing', () {
        expect(NamingRule.tryFromMap({'pattern': '{{name}}'}), isNull);
      });

      test('should return null when `on` key is an empty list', () {
        expect(NamingRule.tryFromMap({'on': <String>[], 'pattern': '{{name}}'}), isNull);
      });

      test('should return null when `pattern` and `grammar` are both missing', () {
        expect(NamingRule.tryFromMap({'on': ['entity']}), isNull);
      });
    });
  });

  group('NamingConventionsConfig', () {
    group('fromMap factory', () {
      group('with valid rules', () {
        test('should parse all valid rules and ignore malformed ones', () {
          final yamlData = {
            ConfigKey.root.namings: [
              {'on': 'model', 'pattern': '{{name}}Dto'},
              {'on': 'entity', 'pattern': '{{name}}Object', 'antipattern': '{{name}}Entity'},
              {'on': ['usecase', 'usecase.parameter'], 'grammar': '{{verb}}{{noun}}Action'},
              {'pattern': 'InvalidRuleMissingOn'}, // Malformed rule to be ignored
            ],
          };

          final config = NamingConventionsConfig.fromMap(yamlData);

          // Test 1: Simple rule
          final modelRule = config.ruleFor(ArchComponent.model);
          expect(modelRule, isNotNull);
          expect(modelRule!.pattern, '{{name}}Dto');
          expect(modelRule.antipattern, isNull);
          expect(modelRule.grammar, isNull);

          // Test 2: Rule with antipattern
          final entityRule = config.ruleFor(ArchComponent.entity);
          expect(entityRule, isNotNull);
          expect(entityRule!.pattern, '{{name}}Object');
          expect(entityRule.antipattern, '{{name}}Entity');

          // Test 3: Rule with grammar (and defaulted pattern) on multiple components
          final useCaseRule = config.ruleFor(ArchComponent.usecase);
          expect(useCaseRule, isNotNull);
          expect(useCaseRule!.pattern, '{{name}}'); // Verify pattern default
          expect(useCaseRule.grammar, '{{verb}}{{noun}}Action');

          // Verify the same rule instance is used for all its `on` keys
          final useCaseParamRule = config.ruleFor(ArchComponent.usecaseParameter);
          expect(useCaseParamRule, isNotNull);
          expect(useCaseParamRule, same(useCaseRule), reason: 'Should be the same rule object');
        });
      });

      group('with empty or malformed data', () {
        test('should return an empty list of rules when key is missing or list is empty', () {
          // Scenario 1: Key is missing
          final config1 = NamingConventionsConfig.fromMap({});
          expect(config1.rules, isEmpty);

          // Scenario 2: Value is an empty list
          final config2 = NamingConventionsConfig.fromMap({ConfigKey.root.namings: <String>[]});
          expect(config2.rules, isEmpty);
        });

        test('should create a config that ignores non-map items in the list', () {
          final yamlData = {
            ConfigKey.root.namings: [
              {'on': 'model', 'pattern': '{{name}}Dto'},
              'a_random_string', // Malformed item
              null, // Malformed item
              123, // Malformed item
            ],
          };

          final config = NamingConventionsConfig.fromMap(yamlData);
          expect(config.rules, hasLength(1));
          expect(config.ruleFor(ArchComponent.model), isNotNull);
        });
      });
    });
  });
}
