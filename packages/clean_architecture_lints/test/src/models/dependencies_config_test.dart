// test/src/models/configs/dependencies_config_test.dart

import 'package:clean_architecture_lints/src/models/configs/dependencies_config.dart';
import 'package:clean_architecture_lints/src/utils/config/config_keys.dart';
import 'package:test/test.dart';

void main() {
  group('DependenciesConfig Models', () {
    group('DependencyDetail', () {
      test('should parse correctly when component and package are lists', () {
        final map = {
          'component': ['domain', 'usecase'],
          'package': ['package:one', 'package:two'],
        };
        final detail = DependencyDetail.fromMap(map);
        expect(detail.components, ['domain', 'usecase']);
        expect(detail.packages, ['package:one', 'package:two']);
        expect(detail.isNotEmpty, isTrue);
      });

      test('should parse correctly when component and package are single strings', () {
        final map = {'component': 'domain', 'package': 'package:one'};
        final detail = DependencyDetail.fromMap(map);
        expect(detail.components, ['domain']);
        expect(detail.packages, ['package:one']);
        expect(detail.isNotEmpty, isTrue);
      });

      test('should return empty lists for missing keys', () {
        final detail = DependencyDetail.fromMap({});
        expect(detail.components, isEmpty);
        expect(detail.packages, isEmpty);
        expect(detail.isNotEmpty, isFalse);
      });
    });

    group('DependencyRule', () {
      test('should parse a complete rule with allowed and forbidden blocks', () {
        final map = {
          'on': 'domain',
          'allowed': {'component': 'entity'},
          'forbidden': {'package': 'package:flutter/material.dart'},
        };
        final rule = DependencyRule.fromMap(map);
        expect(rule, isNotNull);
        expect(rule!.on, ['domain']);
        expect(rule.allowed.components, ['entity']);
        expect(rule.forbidden.packages, ['package:flutter/material.dart']);
      });

      test('should return null when "on" key is missing', () {
        final map = {
          'allowed': {'component': 'entity'},
        };
        expect(DependencyRule.fromMap(map), isNull);
      });

      test('should create empty details for missing allowed/forbidden blocks', () {
        final map = {'on': 'domain'};
        final rule = DependencyRule.fromMap(map);
        expect(rule, isNotNull);
        expect(rule!.allowed.isEmpty, isTrue);
        expect(rule.forbidden.isEmpty, isTrue);
      });
    });

    group('DependenciesConfig', () {
      test('should parse a full list of valid location rules', () {
        final configMap = {
          ConfigKey.root.dependencies: [
            {
              'on': 'domain',
              'forbidden': {
                'component': ['data', 'presentation'],
              },
            },
            {
              'on': ['usecase', 'port'],
              // FIX: Changed key from 'port' to 'component' to match ConfigKeys
              'allowed': {'component': 'entity'},
            },
          ],
        };

        final config = DependenciesConfig.fromMap(configMap);
        expect(config.rules, hasLength(2));

        final domainRule = config.ruleFor(.domain);
        expect(domainRule, isNotNull);
        expect(domainRule!.forbidden.components, ['data', 'presentation']);

        final usecaseRule = config.ruleFor(.usecase);
        expect(usecaseRule, isNotNull);
        expect(usecaseRule!.allowed.components, ['entity']);

        // Verify that the map correctly links both 'on' keys to the same rule.
        expect(config.ruleFor(.usecase), same(usecaseRule));
        expect(config.ruleFor(.port), same(usecaseRule));
      });

      test('should ignore malformed rules in the list', () {
        final configMap = {
          ConfigKey.root.dependencies: [
            {
              'on': 'domain',
              'allowed': {'component': 'entity'},
            },
            {
              'allowed': {'component': 'model'},
            }, // Invalid, missing 'on'
            'not_a_map', // Invalid
          ],
        };
        final config = DependenciesConfig.fromMap(configMap);
        expect(config.rules, hasLength(1));
        expect(config.ruleFor(.domain), isNotNull);
      });

      test('should create an empty config when the locations key is missing or empty', () {
        final config1 = DependenciesConfig.fromMap({});
        expect(config1.rules, isEmpty);

        final config2 = DependenciesConfig.fromMap({
          ConfigKey.root.dependencies: <Map<String, dynamic>>[],
        });
        expect(config2.rules, isEmpty);
      });
    });
  });
}
