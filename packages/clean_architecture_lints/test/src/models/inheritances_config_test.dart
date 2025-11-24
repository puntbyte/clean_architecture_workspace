import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
// We import the main config file because InheritanceDetail/Rule are parts of it.
import 'package:test/test.dart';

void main() {
  group('InheritanceDetail', () {
    group('fromMapWithExpansion', () {
      test('should create single detail from simple name/import', () {
        final map = {
          'name': 'BaseEntity',
          'import': 'package:core/entity.dart',
        };
        final details = InheritanceDetail.fromMapWithExpansion(map);

        expect(details, hasLength(1));
        expect(details.first.name, 'BaseEntity');
        expect(details.first.import, 'package:core/entity.dart');
        expect(details.first.component, isNull);
      });

      test('should create multiple details from list of names', () {
        final map = {
          'name': ['UnaryUsecase', 'NullaryUsecase'],
          'import': 'package:core/usecase.dart',
        };
        final details = InheritanceDetail.fromMapWithExpansion(map);

        expect(details, hasLength(2));

        expect(details[0].name, 'UnaryUsecase');
        expect(details[0].import, 'package:core/usecase.dart');

        expect(details[1].name, 'NullaryUsecase');
        expect(details[1].import, 'package:core/usecase.dart');
      });

      test('should create detail with component reference', () {
        final map = {
          'component': 'entity',
        };
        final details = InheritanceDetail.fromMapWithExpansion(map);

        expect(details, hasLength(1));
        expect(details.first.component, 'entity');
        expect(details.first.name, isNull);
      });

      test('should return empty list if data is missing', () {
        final map = {'invalid': 'data'};
        final details = InheritanceDetail.fromMapWithExpansion(map);
        expect(details, isEmpty);
      });
    });
  });

  group('InheritanceRule', () {
    group('tryFromMap', () {
      test('should create rule with expanded required details', () {
        final map = {
          'on': 'usecase',
          'required': {
            'name': ['A', 'B'],
            'import': 'pkg:common'
          }
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, 'usecase');
        expect(rule.required, hasLength(2));
        expect(rule.required[0].name, 'A');
        expect(rule.required[1].name, 'B');
      });

      test('should create rule with mixed list of required details', () {
        final map = {
          'on': 'repository',
          'required': [
            {'name': 'SpecificRepo', 'import': 'pkg:repo'},
            {'component': 'port'}
          ]
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(2));
        expect(rule.required[0].name, 'SpecificRepo');
        expect(rule.required[1].component, 'port');
      });

      test('should return null if "on" is missing', () {
        final map = {'required': {'name': 'A'}};
        expect(InheritanceRule.tryFromMap(map), isNull);
      });
    });
  });

  group('InheritancesConfig', () {
    group('fromMap', () {
      test('should parse complete configuration', () {
        final map = {
          'inheritances': [
            {
              'on': 'usecase',
              'required': {
                'name': ['Nullary', 'Unary'],
                'import': 'pkg:usecase'
              }
            },
            {
              'on': 'model',
              'required': {'component': 'entity'}
            }
          ]
        };

        final config = InheritancesConfig.fromMap(map);

        expect(config.rules, hasLength(2));

        final usecaseRule = config.ruleFor('usecase');
        expect(usecaseRule, isNotNull);
        expect(usecaseRule!.required, hasLength(2)); // Nullary + Unary
        expect(usecaseRule.required.map((e) => e.name), containsAll(['Nullary', 'Unary']));

        final modelRule = config.ruleFor('model');
        expect(modelRule, isNotNull);
        expect(modelRule!.required.first.component, 'entity');
      });

      test('should return empty config if inheritances key is missing', () {
        final config = InheritancesConfig.fromMap({});
        expect(config.rules, isEmpty);
      });
    });
  });
}