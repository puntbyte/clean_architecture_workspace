// test/src/models/type_safeties_config_test.dart

import 'package:clean_architecture_lints/src/models/type_safeties_config.dart';
import 'package:test/test.dart';

void main() {
  group('TypeSafetyDetail', () {
    group('tryFromMap', () {
      test('should create instance for return type check', () {
        final map = {
          'unsafe_type': 'Future',
          'safe_type': 'FutureEither',
          'import': 'package:example/core.dart',
        };
        final detail = TypeSafetyDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.unsafeType, 'Future');
        expect(detail.safeType, 'FutureEither');
        expect(detail.import, 'package:example/core.dart');
        expect(detail.identifier, isNull);
        expect(detail.isParameterCheck, isFalse);
      });

      test('should create instance for parameter type check', () {
        final map = {
          'unsafe_type': 'int',
          'identifier': 'id',
          'safe_type': 'IntId',
          'import': 'package:example/types.dart',
        };
        final detail = TypeSafetyDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.unsafeType, 'int');
        expect(detail.safeType, 'IntId');
        expect(detail.identifier, 'id');
        expect(detail.import, 'package:example/types.dart');
        expect(detail.isParameterCheck, isTrue);
      });

      test('should return null when unsafe_type is empty', () {
        final map = {
          'unsafe_type': '',
          'safe_type': 'IntId',
        };
        expect(TypeSafetyDetail.tryFromMap(map), isNull);
      });

      test('should return null when safe_type is empty', () {
        final map = {
          'unsafe_type': 'int',
          'safe_type': '',
        };
        expect(TypeSafetyDetail.tryFromMap(map), isNull);
      });

      test('should return null when both types are missing', () {
        final map = {'identifier': 'id'};
        expect(TypeSafetyDetail.tryFromMap(map), isNull);
      });

      test('should create instance without import', () {
        final map = {
          'unsafe_type': 'String',
          'safe_type': 'SafeString',
        };
        final detail = TypeSafetyDetail.tryFromMap(map);

        expect(detail, isNotNull);
        expect(detail!.import, isNull);
      });
    });
  });

  group('TypeSafetyRule', () {
    group('fromMap', () {
      test('should parse rule with return type check', () {
        final map = {
          'on': ['usecase', 'contract'],
          'returns': {
            'unsafe_type': 'Future',
            'safe_type': 'FutureEither',
          },
        };
        final rule = TypeSafetyRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, ['usecase', 'contract']);
        expect(rule.returns, hasLength(1));
        expect(rule.returns.first.unsafeType, 'Future');
        expect(rule.returns.first.safeType, 'FutureEither');
        expect(rule.parameters, isEmpty);
        expect(rule.isValid, isTrue);
      });

      test('should parse rule with parameter checks', () {
        final map = {
          'on': ['contract'],
          'parameters': [
            {
              'unsafe_type': 'int',
              'identifier': 'id',
              'safe_type': 'IntId',
            },
            {
              'unsafe_type': 'String',
              'identifier': 'id',
              'safe_type': 'StringId',
            },
          ],
        };
        final rule = TypeSafetyRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, ['contract']);
        expect(rule.returns, isEmpty);
        expect(rule.parameters, hasLength(2));
        expect(rule.parameters.first.identifier, 'id');
        expect(rule.parameters.first.unsafeType, 'int');
        expect(rule.parameters.last.unsafeType, 'String');
        expect(rule.isValid, isTrue);
      });

      test('should parse rule with both returns and parameters', () {
        final map = {
          'on': ['usecase'],
          'returns': {
            'unsafe_type': 'Future',
            'safe_type': 'FutureEither',
          },
          'parameters': [
            {
              'unsafe_type': 'int',
              'identifier': 'id',
              'safe_type': 'IntId',
            },
          ],
        };
        final rule = TypeSafetyRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.returns, hasLength(1));
        expect(rule.parameters, hasLength(1));
        expect(rule.isValid, isTrue);
      });

      test('should return null when on is empty', () {
        final map = {
          'on': <String>[],
          'returns': {'unsafe_type': 'Future', 'safe_type': 'FutureEither'},
        };
        expect(TypeSafetyRule.tryFromMap(map), isNull);
      });

      test('should return null when on is missing', () {
        final map = {'returns': {'unsafe_type': 'Future', 'safe_type': 'FutureEither'}};
        expect(TypeSafetyRule.tryFromMap(map), isNull);
      });

      test('should return null when both returns and parameters are empty', () {
        final map = {'on': ['usecase']};
        expect(TypeSafetyRule.tryFromMap(map), isNull);
      });

      test('should return null when returns is invalid', () {
        final map = {
          'on': ['usecase'],
          'returns': {'unsafe_type': '', 'safe_type': ''},
        };
        expect(TypeSafetyRule.tryFromMap(map), isNull);
      });

      test('should return null when all parameters are invalid', () {
        final map = {
          'on': ['usecase'],
          'parameters': [
            {'unsafe_type': '', 'safe_type': ''},
            {'identifier': 'id'}, // Missing types
          ],
        };
        expect(TypeSafetyRule.tryFromMap(map), isNull);
      });

      test('should filter out invalid parameter details', () {
        final map = {
          'on': ['contract'],
          'parameters': [
            {
              'unsafe_type': 'int',
              'identifier': 'id',
              'safe_type': 'IntId',
            },
            {
              'unsafe_type': '', // Invalid
              'identifier': 'name',
              'safe_type': 'StringId',
            },
            {
              'identifier': 'email', // Missing types
              'safe_type': 'Email',
            },
            {
              'unsafe_type': 'String',
              'identifier': 'name',
              'safe_type': 'SafeString', // Valid
            },
          ],
        };
        final rule = TypeSafetyRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.parameters, hasLength(2));
        expect(rule.parameters.first.identifier, 'id');
        expect(rule.parameters.last.identifier, 'name');
      });

      test('should parse rule with single string on value', () {
        final map = {
          'on': 'usecase',
          'returns': {'unsafe_type': 'Future', 'safe_type': 'FutureEither'},
        };
        final rule = TypeSafetyRule.tryFromMap(map);

        expect(rule, isNotNull);
        expect(rule!.on, ['usecase']);
      });
    });
  });

  group('TypeSafetiesConfig', () {
    group('fromMap', () {
      test('should parse complete type safety configuration', () {
        final map = {
          'type_safeties': [
            {
              'on': ['usecase', 'contract'],
              'returns': {
                'unsafe_type': 'Future',
                'safe_type': 'FutureEither',
                'import': 'package:example/core.dart',
              },
            },
            {
              'on': ['contract'],
              'parameters': [
                {
                  'unsafe_type': 'int',
                  'identifier': 'id',
                  'safe_type': 'IntId',
                  'import': 'package:example/types.dart',
                },
                {
                  'unsafe_type': 'String',
                  'identifier': 'id',
                  'safe_type': 'StringId',
                },
              ],
            },
          ],
        };

        final config = TypeSafetiesConfig.fromMap(map);

        expect(config.rules, hasLength(2));

        final returnRule = config.rules.first;
        expect(returnRule.on, contains('usecase'));
        expect(returnRule.on, contains('contract'));
        expect(returnRule.returns, hasLength(1));
        expect(returnRule.returns.first.unsafeType, 'Future');
        expect(returnRule.returns.first.import, 'package:example/core.dart');
        expect(returnRule.parameters, isEmpty);

        final paramRule = config.rules.last;
        expect(paramRule.on, ['contract']);
        expect(paramRule.returns, isEmpty);
        expect(paramRule.parameters, hasLength(2));
        expect(paramRule.parameters.first.identifier, 'id');
        expect(paramRule.parameters.first.unsafeType, 'int');
        expect(paramRule.parameters.first.import, 'package:example/types.dart');
        expect(paramRule.parameters.last.unsafeType, 'String');
        expect(paramRule.parameters.last.import, isNull);
      });

      test('should return empty rules when type_safeties is missing', () {
        final config = TypeSafetiesConfig.fromMap({});
        expect(config.rules, isEmpty);
      });

      test('should return empty rules when type_safeties is null', () {
        final config = TypeSafetiesConfig.fromMap({'type_safeties': null});
        expect(config.rules, isEmpty);
      });

      test('should gracefully ignore malformed rules', () {
        final map = {
          'type_safeties': [
            'not_a_map',
            {
              'on': ['usecase'],
              'returns': {
                'unsafe_type': 'Future',
                'safe_type': 'FutureEither',
              },
            }, // Valid
            {
              'on': ['contract'],
              'parameters': [
                {'unsafe_type': '', 'safe_type': ''}, // Invalid
              ],
            }, // Invalid
          ],
        };

        final config = TypeSafetiesConfig.fromMap(map);
        expect(config.rules, hasLength(1));
        expect(config.rules.first.returns.first.safeType, 'FutureEither');
      });

      test('should handle empty type_safeties list', () {
        final config = TypeSafetiesConfig.fromMap({'type_safeties': <String>[]});
        expect(config.rules, isEmpty);
      });
    });

    group('rulesFor', () {
      test('should return rules for specific component ID', () {
        final config = TypeSafetiesConfig.fromMap({
          'type_safeties': [
            {
              'on': ['usecase'],
              'returns': {'unsafe_type': 'Future', 'safe_type': 'FutureEither'},
            },
            {
              'on': ['contract'],
              'parameters': [
                {'unsafe_type': 'int', 'identifier': 'id', 'safe_type': 'IntId'},
              ],
            },
          ],
        });

        final useCaseRules = config.rulesFor('usecase');
        expect(useCaseRules, hasLength(1));
        expect(useCaseRules.first.returns, isNotEmpty);

        final contractRules = config.rulesFor('contract');
        expect(contractRules, hasLength(1));
        expect(contractRules.first.parameters, isNotEmpty);

        final entityRules = config.rulesFor('entity');
        expect(entityRules, isEmpty);
      });

      test('should return multiple rules for component with multiple matches', () {
        final config = TypeSafetiesConfig.fromMap({
          'type_safeties': [
            {
              'on': ['usecase'],
              'returns': {'unsafe_type': 'Future', 'safe_type': 'FutureEither'},
            },
            {
              'on': ['usecase', 'contract'],
              'parameters': [
                {'unsafe_type': 'int', 'identifier': 'id', 'safe_type': 'IntId'},
              ],
            },
          ],
        });

        final useCaseRules = config.rulesFor('usecase');
        expect(useCaseRules, hasLength(2));
      });
    });

    group('parameterRulesFor', () {
      test('should return parameter rules matching component and identifier', () {
        final config = TypeSafetiesConfig.fromMap({
          'type_safeties': [
            {
              'on': ['contract'],
              'parameters': [
                {
                  'unsafe_type': 'int',
                  'identifier': 'id',
                  'safe_type': 'IntId',
                },
                {
                  'unsafe_type': 'String',
                  'identifier': 'name',
                  'safe_type': 'StringId',
                },
              ],
            },
          ],
        });

        final idRules = config.parameterRulesFor('contract', 'id');
        expect(idRules, hasLength(1));
        expect(idRules.first.unsafeType, 'int');

        final nameRules = config.parameterRulesFor('contract', 'name');
        expect(nameRules, hasLength(1));
        expect(nameRules.first.unsafeType, 'String');

        final emailRules = config.parameterRulesFor('contract', 'email');
        expect(emailRules, isEmpty);
      });

      test('should collect parameter rules from multiple rules', () {
        final config = TypeSafetiesConfig.fromMap({
          'type_safeties': [
            {
              'on': ['contract', 'repository'],
              'parameters': [
                {'unsafe_type': 'int', 'identifier': 'id', 'safe_type': 'IntId'},
              ],
            },
            {
              'on': ['contract'],
              'parameters': [
                {'unsafe_type': 'String', 'identifier': 'id', 'safe_type': 'StringId'},
              ],
            },
          ],
        });

        final contractIdRules = config.parameterRulesFor('contract', 'id');
        expect(contractIdRules, hasLength(2));
        expect(contractIdRules.any((d) => d.unsafeType == 'int'), isTrue);
        expect(contractIdRules.any((d) => d.unsafeType == 'String'), isTrue);

        final repositoryIdRules = config.parameterRulesFor('repository', 'id');
        expect(repositoryIdRules, hasLength(1));
        expect(repositoryIdRules.first.unsafeType, 'int');
      });
    });

    group('returnRulesFor', () {
      test('should return return type rules for component', () {
        final config = TypeSafetiesConfig.fromMap({
          'type_safeties': [
            {
              'on': ['usecase', 'contract'],
              'returns': {'unsafe_type': 'Future', 'safe_type': 'FutureEither'},
            },
            {
              'on': ['repository'],
              'returns': {'unsafe_type': 'dynamic', 'safe_type': 'Unknown'},
            },
          ],
        });

        final useCaseReturns = config.returnRulesFor('usecase');
        expect(useCaseReturns, hasLength(1));
        expect(useCaseReturns.first.unsafeType, 'Future');

        final contractReturns = config.returnRulesFor('contract');
        expect(contractReturns, hasLength(1));
        expect(contractReturns.first.unsafeType, 'Future');

        final repositoryReturns = config.returnRulesFor('repository');
        expect(repositoryReturns, hasLength(1));
        expect(repositoryReturns.first.unsafeType, 'dynamic');
      });

      test('should return empty list for component with no return rules', () {
        final config = TypeSafetiesConfig.fromMap({
          'type_safeties': [
            {
              'on': ['contract'],
              'parameters': [
                {'unsafe_type': 'int', 'identifier': 'id', 'safe_type': 'IntId'},
              ],
            },
          ],
        });

        expect(config.returnRulesFor('contract'), isEmpty);
      });
    });
  });
}
