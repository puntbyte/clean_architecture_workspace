// test/src/models/configs/type_safeties_config_test.dart

import 'package:clean_architecture_lints/src/models/configs/type_safeties_config.dart';
import 'package:test/test.dart';

void main() {
  group('TypeSafetyDetail', () {
    group('fromMap', () {
      test('should parse all fields correctly', () {
        final map = {
          'kind': 'parameter',
          'type': 'IntId',
          'definition': 'identity.integer',
          'import': 'package:core/types.dart',
          'component': 'model',
          'identifier': 'id',
        };
        final detail = TypeSafetyDetail.fromMap(map);

        expect(detail.kind, 'parameter');
        expect(detail.type, 'IntId');
        expect(detail.definition, 'identity.integer');
        expect(detail.import, 'package:core/types.dart');
        expect(detail.component, 'model');
        expect(detail.identifier, 'id');
      });

      test('should handle missing optional fields', () {
        final map = {'type': 'Future'};
        final detail = TypeSafetyDetail.fromMap(map);

        expect(detail.type, 'Future');
        expect(detail.kind, isNull);
        expect(detail.definition, isNull);
        expect(detail.import, isNull);
        expect(detail.component, isNull);
        expect(detail.identifier, isNull);
      });
    });
  });

  group('TypeSafetyRule', () {
    group('tryFromMap', () {
      test('should return null if "on" is missing or empty', () {
        expect(TypeSafetyRule.tryFromMap({}), isNull);
        expect(TypeSafetyRule.tryFromMap({'on': []}), isNull);
      });

      test('should parse "allowed" and "forbidden" as Lists of Maps', () {
        final map = {
          'on': ['port'],
          'allowed': [
            {'kind': 'return', 'type': 'FutureEither'},
            {'kind': 'parameter', 'type': 'IntId'},
          ],
          'forbidden': [
            {'kind': 'return', 'type': 'Future'},
          ],
        };

        final rule = TypeSafetyRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, contains('port'));

        expect(rule.allowed, hasLength(2));
        expect(rule.allowed[0].type, 'FutureEither');
        expect(rule.allowed[1].type, 'IntId');

        expect(rule.forbidden, hasLength(1));
        expect(rule.forbidden[0].type, 'Future');
      });

      test('should parse "allowed" and "forbidden" as Single Map (Shorthand)', () {
        // In YAML, users might write: allowed: { type: 'FutureEither' }
        // instead of allowed: [ { type: 'FutureEither' } ]
        final map = {
          'on': ['port'],
          'allowed': {'kind': 'return', 'type': 'FutureEither'},
          'forbidden': {'kind': 'return', 'type': 'Future'},
        };

        final rule = TypeSafetyRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.allowed, hasLength(1));
        expect(rule.allowed.first.type, 'FutureEither');

        expect(rule.forbidden, hasLength(1));
        expect(rule.forbidden.first.type, 'Future');
      });

      test('should handle empty or null lists gracefully', () {
        final map = {
          'on': ['port'],
          'allowed': null, // Missing key in YAML
          'forbidden': [], // Empty list in YAML
        };

        final rule = TypeSafetyRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.allowed, isEmpty);
        expect(rule.forbidden, isEmpty);
      });
    });
  });

  group('TypeSafetiesConfig', () {
    group('fromMap', () {
      test('should parse a list of rules', () {
        final map = {
          'type_safeties': [
            {
              'on': ['port', 'usecase'],
              'allowed': {'type': 'FutureEither'},
            },
            {
              'on': ['source'],
              'allowed': {'type': 'Future'},
            },
          ],
        };

        final config = TypeSafetiesConfig.fromMap(map);

        expect(config.rules, hasLength(2));
        expect(config.rules[0].on, containsAll(['port', 'usecase']));
        expect(config.rules[1].on, contains('source'));
      });

      test('should return empty config if key is missing', () {
        final config = TypeSafetiesConfig.fromMap({});
        expect(config.rules, isEmpty);
      });
    });

    group('rulesFor', () {
      test('should return matching rules for a component ID', () {
        final map = {
          'type_safeties': [
            {
              'on': ['port', 'usecase'], // Rule A
              'forbidden': {'type': 'Future'},
            },
            {
              'on': ['port'], // Rule B
              'allowed': {'type': 'IntId'},
            },
            {
              'on': ['source'], // Rule C
              'allowed': {'type': 'String'},
            },
          ],
        };

        final config = TypeSafetiesConfig.fromMap(map);

        // 'port' matches Rule A and Rule B
        final portRules = config.rulesFor(.port);
        expect(portRules, hasLength(2));
        expect(portRules[0].forbidden.first.type, 'Future');
        expect(portRules[1].allowed.first.type, 'IntId');

        // 'usecase' matches Rule A only
        final useCaseRules = config.rulesFor(.usecase);
        expect(useCaseRules, hasLength(1));

        // 'repository' matches nothing
        final repoRules = config.rulesFor(.repository);
        expect(repoRules, isEmpty);
      });
    });
  });
}
