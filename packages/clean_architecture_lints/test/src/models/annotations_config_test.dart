// test/src/models/annotations_config_test.dart

import 'package:clean_architecture_lints/src/models/configs/annotations_config.dart';
import 'package:test/test.dart';

void main() {
  group('AnnotationDetail', () {
    group('tryFromMap', () {
      test('should create instance with valid name', () {
        final map = {'name': 'Injectable'};
        final detail = AnnotationDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.name, 'Injectable');
        expect(detail.import, isNull);
      });

      test('should create instance with name and import', () {
        final map = {
          'name': 'Injectable',
          'import': 'package:injectable/injectable.dart',
        };
        final detail = AnnotationDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.name, 'Injectable');
        expect(detail.import, 'package:injectable/injectable.dart');
      });

      test('should return null when name is empty', () {
        final map = {'name': ''};
        expect(AnnotationDetail.tryFromMap(map), isNull);
      });

      test('should return null when name key is missing', () {
        final map = {'import': 'package:test/test.dart'};
        expect(AnnotationDetail.tryFromMap(map), isNull);
      });

      test('should return null for non-string name value', () {
        final map = {'name': 123};
        expect(AnnotationDetail.tryFromMap(map), isNull);
      });

      test('should ignore extra properties in map', () {
        final map = {
          'name': 'Entity',
          'import': 'package:test/test.dart',
          'extra': 'ignored',
        };
        final detail = AnnotationDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.name, 'Entity');
        expect(detail.import, 'package:test/test.dart');
      });

      test('should handle null import value', () {
        final map = {
          'name': 'Entity',
          'import': null,
        };
        final detail = AnnotationDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.name, 'Entity');
        expect(detail.import, isNull);
      });
    });
  });

  group('AnnotationRule', () {
    group('tryFromMap', () {
      test('should create rule with valid on list', () {
        final map = {
          'on': ['usecase'],
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, ['usecase']);
        expect(rule.required, isEmpty);
        expect(rule.forbidden, isEmpty);
        expect(rule.allowed, isEmpty);
      });

      test('should create rule with single string on value', () {
        final map = {'on': 'usecase'};
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, ['usecase']);
      });

      test('should create rule with required annotations', () {
        final map = {
          'on': ['usecase'],
          'required': {'name': 'Injectable'},
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(1));
        expect(rule.required.first.name, 'Injectable');
      });

      test('should create rule with allowed annotations', () {
        final map = {
          'on': ['repository'],
          'allowed': {'name': 'WithCache'},
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.allowed, hasLength(1));
        expect(rule.allowed.first.name, 'WithCache');
      });

      test('should create rule with forbidden annotations', () {
        final map = {
          'on': ['entity'],
          'forbidden': {'name': 'Injectable'},
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.forbidden, hasLength(1));
        expect(rule.forbidden.first.name, 'Injectable');
      });

      test('should create rule with multiple on values', () {
        final map = {
          'on': ['usecase', 'entity'],
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, ['usecase', 'entity']);
      });

      test('should parse list of maps for required annotations', () {
        final map = {
          'on': ['usecase'],
          'required': [
            {'name': 'Injectable'},
            {'name': 'Singleton'},
          ],
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(2));
        expect(rule.required.first.name, 'Injectable');
        expect(rule.required.last.name, 'Singleton');
      });

      test('should parse list of maps for allowed annotations', () {
        final map = {
          'on': ['model'],
          'allowed': [
            {'name': 'freezed'},
            {'name': 'MappableClass'},
          ],
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.allowed, hasLength(2));
        expect(rule.allowed.first.name, 'freezed');
        expect(rule.allowed.last.name, 'MappableClass');
      });

      test('should parse list of maps for forbidden annotations', () {
        final map = {
          'on': ['entity'],
          'forbidden': [
            {'name': 'Injectable'},
            {'name': 'LazySingleton'},
          ],
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.forbidden, hasLength(2));
        expect(rule.forbidden.first.name, 'Injectable');
        expect(rule.forbidden.last.name, 'LazySingleton');
      });

      test('should handle name list in single map for required annotations', () {
        final map = {
          'on': ['entity'],
          'required': {
            'name': ['Injectable', 'Singleton'],
          },
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(2));
        expect(rule.required.first.name, 'Injectable');
        expect(rule.required.last.name, 'Singleton');
      });

      test('should handle name list in single map for forbidden annotations', () {
        final map = {
          'on': ['entity'],
          'forbidden': {
            'name': ['Injectable', 'LazySingleton'],
          },
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.forbidden, hasLength(2));
        expect(rule.forbidden.first.name, 'Injectable');
        expect(rule.forbidden.last.name, 'LazySingleton');
      });

      test('should handle name list in single map for allowed annotations', () {
        final map = {
          'on': ['widget'],
          'allowed': {
            'name': ['Immutable', 'Stateful'],
          },
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.allowed, hasLength(2));
        expect(rule.allowed.first.name, 'Immutable');
        expect(rule.allowed.last.name, 'Stateful');
      });

      test('should handle name list in list of maps', () {
        final map = {
          'on': ['entity'],
          'required': [
            {
              'name': ['Name1', 'Name2'],
            },
            {'name': 'Name3'},
          ],
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(3));
        expect(rule.required[0].name, 'Name1');
        expect(rule.required[1].name, 'Name2');
        expect(rule.required[2].name, 'Name3');
      });

      test('should return null when on is empty', () {
        final map = {'on': <dynamic>[]};
        expect(AnnotationRule.tryFromMap(map), isNull);
      });

      test('should return null when on is missing', () {
        final map = {
          'required': {'name': 'Injectable'},
        };
        expect(AnnotationRule.tryFromMap(map), isNull);
      });

      test('should ignore invalid data in lists', () {
        final map = {
          'on': ['usecase'],
          'required': [
            {'name': 'Valid'},
            'not_a_map',
            123,
            {'name': 'AlsoValid'},
            {'invalid': 'no_name'},
          ],
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(2));
        expect(rule.required.first.name, 'Valid');
        expect(rule.required.last.name, 'AlsoValid');
      });

      test('should maintain import for name list in single map', () {
        final map = {
          'on': ['entity'],
          'forbidden': {
            'name': ['Injectable', 'LazySingleton'],
            'import': 'package:injectable/injectable.dart',
          },
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.forbidden, hasLength(2));
        expect(
          rule.forbidden.every((d) => d.import == 'package:injectable/injectable.dart'),
          isTrue,
        );
      });

      test('should maintain import for name list in list of maps', () {
        final map = {
          'on': ['entity'],
          'required': [
            {
              'name': ['Name1', 'Name2'],
              'import': 'package:test/core.dart',
            },
          ],
        };
        final rule = AnnotationRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(2));
        expect(rule.required.every((d) => d.import == 'package:test/core.dart'), isTrue);
      });
    });
  });

  group('AnnotationsConfig', () {
    group('fromMap', () {
      test('should parse a complete list of annotation rules', () {
        final map = {
          'annotations': [
            {
              'on': ['usecase'],
              'required': {
                'name': 'Injectable',
                'import': 'package:injectable/injectable.dart',
              },
            },
            {
              'on': ['repository'],
              'required': [
                {'name': 'LazySingleton'},
              ],
              'allowed': {'name': 'WithCache'},
            },
            {
              'on': ['entity'],
              'forbidden': {
                'name': ['Injectable', 'LazySingleton'],
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
        };

        final config = AnnotationsConfig.fromMap(map);

        expect(config.rules, hasLength(4));

        final useCaseRule = config.ruleFor(.usecase);
        expect(useCaseRule, isNotNull);
        expect(useCaseRule!.on, contains('usecase'));
        expect(useCaseRule.required, hasLength(1));
        expect(useCaseRule.required.first.name, 'Injectable');
        expect(useCaseRule.required.first.import, 'package:injectable/injectable.dart');

        final repositoryRule = config.ruleFor(.repository);
        expect(repositoryRule, isNotNull);
        expect(repositoryRule!.required, hasLength(1));
        expect(repositoryRule.required.first.name, 'LazySingleton');
        expect(repositoryRule.allowed, hasLength(1));
        expect(repositoryRule.allowed.first.name, 'WithCache');

        final entityRule = config.ruleFor(.entity);
        expect(entityRule, isNotNull);
        expect(entityRule!.forbidden, hasLength(2));
        expect(entityRule.forbidden.any((d) => d.name == 'Injectable'), isTrue);
        expect(entityRule.forbidden.any((d) => d.name == 'LazySingleton'), isTrue);

        final modelRule = config.ruleFor(.model);
        expect(modelRule, isNotNull);
        expect(modelRule!.allowed, hasLength(2));
        expect(modelRule.allowed.any((d) => d.name == 'freezed'), isTrue);
        expect(modelRule.allowed.any((d) => d.name == 'MappableClass'), isTrue);
      });

      test('should return an empty list of rules when annotations key is missing', () {
        expect(AnnotationsConfig.fromMap({}).rules, isEmpty);
      });

      test('should return an empty list of rules when annotations value is null', () {
        expect(AnnotationsConfig.fromMap({'annotations': null}).rules, isEmpty);
      });

      test('should gracefully ignore malformed rules in the list', () {
        final map = {
          'annotations': [
            'not_a_map',
            {
              'on': ['usecase'],
              'required': {'name': 'required'},
            }, // Valid
            {
              'required': {'name': 'Singleton'},
            }, // Invalid (missing 'on')
          ],
        };

        final config = AnnotationsConfig.fromMap(map);
        expect(config.rules, hasLength(1));
        expect(config.rules.first.on, contains('usecase'));
      });

      test('should handle empty annotations list', () {
        final config = AnnotationsConfig.fromMap({'annotations': <dynamic>[]});
        expect(config.rules, isEmpty);
      });
    });

    group('ruleFor', () {
      test('should return rule when component ID matches single on value', () {
        final config = AnnotationsConfig.fromMap({
          'annotations': [
            {
              'on': ['entity'],
              'required': {'name': 'Entity'},
            },
          ],
        });

        final rule = config.ruleFor(.entity);
        expect(rule, isNotNull);
        expect(rule!.on, contains('entity'));
      });

      test('should return rule when component ID matches one of multiple on values', () {
        final config = AnnotationsConfig.fromMap({
          'annotations': [
            {
              'on': ['usecase', 'entity'],
              'required': {'name': 'Required'},
            },
          ],
        });

        expect(config.ruleFor(.usecase), isNotNull);
        expect(config.ruleFor(.entity), isNotNull);
        expect(config.ruleFor(.widget), isNull);
      });

      test('should return null when no rule matches component ID', () {
        final config = AnnotationsConfig.fromMap({
          'annotations': [
            {
              'on': ['entity'],
              'required': {'name': 'Entity'},
            },
          ],
        });

        expect(config.ruleFor(.widget), isNull);
      });

      test('should return null for empty config', () {
        expect(AnnotationsConfig.fromMap({}).ruleFor(.entity), isNull);
      });
    });

    group('requiredFor', () {
      test('should return required annotations when rule exists', () {
        final config = AnnotationsConfig.fromMap({
          'annotations': [
            {
              'on': ['usecase'],
              'required': [
                {'name': 'Injectable'},
                {'name': 'Singleton'},
              ],
            },
          ],
        });

        final required = config.requiredFor(.usecase);
        expect(required, hasLength(2));
        expect(required.first.name, 'Injectable');
        expect(required.last.name, 'Singleton');
      });

      test('should return empty list when no rule exists', () {
        final config = AnnotationsConfig.fromMap({});
        expect(config.requiredFor(.usecase), isEmpty);
      });

      test('should return empty list when rule has no required annotations', () {
        final config = AnnotationsConfig.fromMap({
          'annotations': [
            {
              'on': ['usecase'],
              'allowed': {'name': 'Optional'},
            },
          ],
        });

        expect(config.requiredFor(.usecase), isEmpty);
      });
    });
  });
}
