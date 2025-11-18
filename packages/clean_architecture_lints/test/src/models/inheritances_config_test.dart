// test/src/models/inheritances_config_test.dart

import 'package:clean_architecture_lints/src/models/inheritances_config.dart';
import 'package:test/test.dart';

void main() {
  group('InheritanceDetail', () {
    group('tryFromMap', () {
      test('should create instance with valid name and import', () {
        final map = {
          'name': 'BaseEntity',
          'import': 'package:core/entity.dart',
        };
        final detail = InheritanceDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.name, 'BaseEntity');
        expect(detail.import, 'package:core/entity.dart');
      });

      test('should return null when name is empty', () {
        final map = {'name': '', 'import': 'package:core/entity.dart'};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });

      test('should return null when import is empty', () {
        final map = {'name': 'BaseEntity', 'import': ''};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });

      test('should return null when name key is missing', () {
        final map = {'import': 'package:core/entity.dart'};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });

      test('should return null when import key is missing', () {
        final map = {'name': 'BaseEntity'};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });

      test('should return null for non-string name value', () {
        final map = {'name': 123, 'import': 'package:core/entity.dart'};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });

      test('should return null for non-string import value', () {
        final map = {'name': 'BaseEntity', 'import': 123};
        expect(InheritanceDetail.tryFromMap(map), isNull);
      });

      test('should ignore extra properties in map', () {
        final map = {
          'name': 'BaseEntity',
          'import': 'package:core/entity.dart',
          'extra': 'ignored',
        };
        final detail = InheritanceDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.name, 'BaseEntity');
        expect(detail.import, 'package:core/entity.dart');
      });
    });
  });

  group('InheritanceRule', () {
    group('tryFromMap', () {
      test('should create rule with valid on value', () {
        final map = {'on': 'entity'};
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, 'entity');
        expect(rule.required, isEmpty);
        expect(rule.allowed, isEmpty);
        expect(rule.forbidden, isEmpty);
      });

      test('should create rule with required inheritance detail', () {
        final map = {
          'on': 'entity',
          'required': {'name': 'BaseEntity', 'import': 'package:core/entity.dart'},
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(1));
        expect(rule.required.first.name, 'BaseEntity');
        expect(rule.required.first.import, 'package:core/entity.dart');
        expect(rule.allowed, isEmpty);
        expect(rule.forbidden, isEmpty);
      });

      test('should create rule with allowed inheritance detail', () {
        final map = {
          'on': 'widget',
          'allowed': {'name': 'HookWidget', 'import': 'package:flutter_hooks/flutter_hooks.dart'},
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.allowed, hasLength(1));
        expect(rule.allowed.first.name, 'HookWidget');
        expect(rule.allowed.first.import, 'package:flutter_hooks/flutter_hooks.dart');
      });

      test('should create rule with forbidden inheritance detail', () {
        final map = {
          'on': 'entity',
          'forbidden': {'name': 'StatefulWidget', 'import': 'package:flutter/widgets.dart'},
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.forbidden, hasLength(1));
        expect(rule.forbidden.first.name, 'StatefulWidget');
      });

      test('should parse list of maps for required details', () {
        final map = {
          'on': 'usecase',
          'required': [
            {'name': 'UnaryUsecase', 'import': 'package:core/usecase.dart'},
            {'name': 'NullaryUsecase', 'import': 'package:core/usecase.dart'},
          ],
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(2));
        expect(rule.required.first.name, 'UnaryUsecase');
        expect(rule.required.last.name, 'NullaryUsecase');
      });

      test('should parse list of maps for allowed details', () {
        final map = {
          'on': 'widget',
          'allowed': [
            {'name': 'HookWidget', 'import': 'package:flutter_hooks/flutter_hooks.dart'},
            {'name': 'ConsumerWidget', 'import': 'package:flutter_riverpod/flutter_riverpod.dart'},
          ],
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.allowed, hasLength(2));
        expect(rule.allowed.first.name, 'HookWidget');
        expect(rule.allowed.last.name, 'ConsumerWidget');
      });

      test('should parse list of maps for forbidden details', () {
        final map = {
          'on': 'entity',
          'forbidden': [
            {'name': 'StatefulWidget', 'import': 'package:flutter/widgets.dart'},
            {'name': 'StatefulElement', 'import': 'package:flutter/widgets.dart'},
          ],
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.forbidden, hasLength(2));
        expect(rule.forbidden.first.name, 'StatefulWidget');
      });

      test('should create rule with all detail types', () {
        final map = {
          'on': 'repository',
          'required': {'name': 'BaseRepo', 'import': 'package:core/repo.dart'},
          'allowed': {'name': 'Cacheable', 'import': 'package:cache/cache.dart'},
          'forbidden': {'name': 'StatefulWidget', 'import': 'package:flutter/widgets.dart'},
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(1));
        expect(rule.allowed, hasLength(1));
        expect(rule.forbidden, hasLength(1));
      });

      test('should return null when on is empty', () {
        final map = {'on': ''};
        expect(InheritanceRule.tryFromMap(map), isNull);
      });

      test('should return null when on is missing', () {
        final map = {'required': {'name': 'Base', 'import': 'pkg:core.dart'}};
        expect(InheritanceRule.tryFromMap(map), isNull);
      });

      test('should filter out null details from lists', () {
        final map = {
          'on': 'entity',
          'required': [
            {'name': 'Valid', 'import': 'pkg:core.dart'},
            {'name': '', 'import': 'pkg:core.dart'}, // Invalid (empty name)
            {'import': 'pkg:core.dart'}, // Invalid (missing name)
            {'name': 'AlsoValid', 'import': 'pkg:core.dart'},
          ],
        };
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, hasLength(2));
        expect(rule.required.first.name, 'Valid');
        expect(rule.required.last.name, 'AlsoValid');
      });

      test('should handle empty lists for all detail types', () {
        final map = {'on': 'entity'};
        final rule = InheritanceRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.required, isEmpty);
        expect(rule.allowed, isEmpty);
        expect(rule.forbidden, isEmpty);
      });
    });
  });

  group('InheritancesConfig', () {
    group('fromMap', () {
      test('should parse a complete list of inheritance rules', () {
        final map = {
          'inheritances': [
            {
              'on': 'usecase',
              'required': [
                {'name': 'MyUnary', 'import': 'package:my_core/my_usecase.dart'},
                {'name': 'MyNullary', 'import': 'package:my_core/my_usecase.dart'},
              ],
            },
            {
              'on': 'widget',
              'forbidden': {'name': 'StatefulWidget', 'import': 'package:flutter/widgets.dart'},
            },
            {
              'on': 'repository',
              'required': {'name': 'BaseRepo', 'import': 'package:core/repo.dart'},
              'allowed': {'name': 'Cacheable', 'import': 'package:cache/cache.dart'},
            },
          ],
        };

        final config = InheritancesConfig.fromMap(map);

        expect(config.rules, hasLength(3));

        final useCaseRule = config.rules.first;
        expect(useCaseRule, isA<InheritanceRule>());
        expect(useCaseRule.on, 'usecase');
        expect(useCaseRule.required, hasLength(2));
        expect(useCaseRule.required.first.name, 'MyUnary');
        expect(useCaseRule.required.last.name, 'MyNullary');
        expect(useCaseRule.allowed, isEmpty);
        expect(useCaseRule.forbidden, isEmpty);

        final widgetRule = config.rules[1];
        expect(widgetRule.on, 'widget');
        expect(widgetRule.forbidden, hasLength(1));
        expect(widgetRule.forbidden.first.name, 'StatefulWidget');
        expect(widgetRule.required, isEmpty);
        expect(widgetRule.allowed, isEmpty);

        final repoRule = config.rules[2];
        expect(repoRule.on, 'repository');
        expect(repoRule.required, hasLength(1));
        expect(repoRule.required.first.name, 'BaseRepo');
        expect(repoRule.allowed, hasLength(1));
        expect(repoRule.allowed.first.name, 'Cacheable');
        expect(repoRule.forbidden, isEmpty);
      });

      test('should return an empty list of rules when the inheritances key is missing', () {
        final map = <String, dynamic>{};
        final config = InheritancesConfig.fromMap(map);

        expect(config.rules, isEmpty);
      });

      test('should gracefully ignore malformed rules in the list', () {
        final map = {
          'inheritances': [
            'not_a_map', // Invalid entry
            {
              'on': 'entity',
              'required': {'name': 'MyEntity', 'import': 'package:my_core/my_entity.dart'},
            }, // Valid entry
            {'required': 'SomeBaseClass'}, // Invalid entry (missing 'on')
          ],
        };

        final config = InheritancesConfig.fromMap(map);

        // Should only have parsed the one valid rule.
        expect(config.rules, hasLength(1));
        expect(config.rules.first.on, 'entity');
      });

      test('should handle empty inheritances list', () {
        final config = InheritancesConfig.fromMap({'inheritances': <String>[]});
        expect(config.rules, isEmpty);
      });

      test('should handle null inheritances value', () {
        final config = InheritancesConfig.fromMap({'inheritances': null});
        expect(config.rules, isEmpty);
      });
    });

    group('ruleFor', () {
      test('should return rule when component ID matches', () {
        final config = InheritancesConfig.fromMap({
          'inheritances': [
            {'on': 'entity', 'required': {'name': 'BaseEntity', 'import': 'pkg:core.dart'}},
          ],
        });

        final rule = config.ruleFor('entity');
        expect(rule, isNotNull);
        expect(rule!.on, 'entity');
      });

      test('should return null when no rule matches component ID', () {
        final config = InheritancesConfig.fromMap({
          'inheritances': [
            {'on': 'entity', 'required': {'name': 'BaseEntity', 'import': 'pkg:core.dart'}},
          ],
        });

        expect(config.ruleFor('widget'), isNull);
      });

      test('should return null for empty config', () {
        expect(InheritancesConfig.fromMap({}).ruleFor('entity'), isNull);
      });

      test('should find correct rule among multiple rules', () {
        final config = InheritancesConfig.fromMap({
          'inheritances': [
            {'on': 'usecase', 'required': {'name': 'BaseUsecase', 'import': 'pkg:core.dart'}},
            {'on': 'entity', 'required': {'name': 'BaseEntity', 'import': 'pkg:core.dart'}},
            {'on': 'repository', 'required': {'name': 'BaseRepo', 'import': 'pkg:core.dart'}},
          ],
        });

        expect(config.ruleFor('usecase')?.on, 'usecase');
        expect(config.ruleFor('entity')?.on, 'entity');
        expect(config.ruleFor('repository')?.on, 'repository');
      });
    });
  });
}
