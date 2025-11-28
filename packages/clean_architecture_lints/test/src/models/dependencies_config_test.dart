// test/src/models/dependencies_config_test.dart


import 'package:clean_architecture_lints/src/models/configs/dependencies_config.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyDetail', () {
    group('fromMap', () {
      test('should parse explicit Map syntax with components and packages', () {
        final input = {
          'component': ['domain', 'manager'],
          'package': ['flutter', 'dart:ui'],
        };
        final detail = DependencyDetail.fromMap(input);

        expect(detail.components, containsAll(['domain', 'manager']));
        expect(detail.packages, containsAll(['flutter', 'dart:ui']));
        expect(detail.isNotEmpty, isTrue);
      });

      test('should parse shorthand List syntax as components', () {
        // Configuration often looks like: allowed: ['domain', 'manager']
        final input = ['domain', 'manager'];
        final detail = DependencyDetail.fromMap(input);

        expect(detail.components, containsAll(['domain', 'manager']));
        expect(detail.packages, isEmpty);
        expect(detail.isNotEmpty, isTrue);
      });

      test('should return empty detail for null input', () {
        final detail = DependencyDetail.fromMap(null);
        expect(detail.isEmpty, isTrue);
      });

      test('should return empty detail for empty map', () {
        final detail = DependencyDetail.fromMap({});
        expect(detail.isEmpty, isTrue);
      });

      test('should return empty detail for empty list', () {
        final detail = DependencyDetail.fromMap([]);
        expect(detail.isEmpty, isTrue);
      });
    });
  });

  group('DependencyRule', () {
    group('fromMap', () {
      test('should parse valid rule with both allowed and forbidden', () {
        final map = {
          'on': 'domain',
          'allowed': ['manager'],
          'forbidden': {
            'package': ['flutter']
          }
        };
        final rule = DependencyRule.fromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, equals(['domain']));

        // Shorthand parsing check
        expect(rule.allowed.components, contains('manager'));

        // Explicit map parsing check
        expect(rule.forbidden.packages, contains('flutter'));
      });

      test('should parse rule with list of targets in "on"', () {
        final map = {
          'on': ['port', 'usecase'],
          'allowed': ['domain']
        };
        final rule = DependencyRule.fromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, containsAll(['port', 'usecase']));
      });

      test('should return null if "on" is missing', () {
        final map = {
          'allowed': ['domain']
        };
        expect(DependencyRule.fromMap(map), isNull);
      });

      test('should return null if "on" is empty', () {
        final map = {
          'on': [],
          'allowed': ['domain']
        };
        expect(DependencyRule.fromMap(map), isNull);
      });
    });
  });

  group('DependenciesConfig', () {
    group('fromMap', () {
      test('should parse list of rules and map them correctly', () {
        final map = {
          'dependencies': [
            {
              'on': 'domain',
              'forbidden': {'package': 'flutter'}
            },
            {
              'on': ['manager', 'bloc'],
              'allowed': ['usecase']
            }
          ]
        };

        final config = DependenciesConfig.fromMap(map);

        expect(config.rules, hasLength(2));

        // Test lookup by single ID
        final domainRule = config.ruleFor('domain');
        expect(domainRule, isNotNull);
        expect(domainRule!.forbidden.packages, contains('flutter'));

        // Test lookup for multiple IDs mapping to same rule
        final managerRule = config.ruleFor('manager');
        final blocRule = config.ruleFor('bloc');

        expect(managerRule, isNotNull);
        expect(blocRule, isNotNull);
        expect(managerRule, same(blocRule)); // Should be the exact same object instance
        expect(managerRule!.allowed.components, contains('usecase'));
      });

      test('should return empty config if dependencies key is missing', () {
        final config = DependenciesConfig.fromMap({});
        expect(config.rules, isEmpty);
        expect(config.ruleFor('domain'), isNull);
      });

      test('should ignore invalid rules in the list', () {
        final map = {
          'dependencies': [
            {'invalid': 'data'}, // Missing 'on'
            {'on': 'data', 'allowed': 'model'} // Valid
          ]
        };

        final config = DependenciesConfig.fromMap(map);
        expect(config.rules, hasLength(1));
        expect(config.ruleFor('data'), isNotNull);
      });
    });
  });
}