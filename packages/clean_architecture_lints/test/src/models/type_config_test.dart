import 'package:clean_architecture_lints/src/models/type_config.dart';
import 'package:test/test.dart';

void main() {
  group('TypeRule', () {
    group('fromMap', () {
      test('should create instance with valid name and import', () {
        final map = {
          'name': 'FutureEither',
          'import': 'package:core/utils.dart',
        };
        final rule = TypeRule.fromMap(map);

        expect(rule.name, 'FutureEither');
        expect(rule.import, 'package:core/utils.dart');
      });

      test('should create instance with name only', () {
        final map = {
          'name': 'Future',
        };
        final rule = TypeRule.fromMap(map);

        expect(rule.name, 'Future');
        expect(rule.import, isNull);
      });

      test('should fallback to empty string if name is missing (or handle gracefully)', () {
        // Assuming standard json extension behavior where missing string defaults to ''
        final map = <String, dynamic>{};
        final rule = TypeRule.fromMap(map);
        expect(rule.name, isEmpty);
      });
    });
  });

  group('TypeConfig', () {
    group('fromMap & get', () {
      test('should flatten nested categories into dot-notation keys', () {
        final map = {
          'type_definitions': {
            // Category 1
            'exception': {
              // Nested Rule
              'base': {
                'name': 'CustomException',
                'import': 'pkg:exc.dart',
              },
              // Nested Rule
              'server': {
                'name': 'ServerException',
              }
            },
            // Category 2
            'result': {
              'wrapper': {
                'name': 'FutureEither',
              }
            }
          }
        };

        final config = TypeConfig.fromMap(map);

        // Test exception.base
        final baseEx = config.get('exception.base');
        expect(baseEx, isNotNull);
        expect(baseEx!.name, 'CustomException');
        expect(baseEx.import, 'pkg:exc.dart');

        // Test exception.server
        final serverEx = config.get('exception.server');
        expect(serverEx, isNotNull);
        expect(serverEx!.name, 'ServerException');

        // Test result.wrapper
        final resultWrapper = config.get('result.wrapper');
        expect(resultWrapper, isNotNull);
        expect(resultWrapper!.name, 'FutureEither');
      });

      test('should handle deep nesting', () {
        final map = {
          'type_definitions': {
            'level1': {
              'level2': {
                'level3': {
                  'name': 'DeepClass',
                }
              }
            }
          }
        };

        final config = TypeConfig.fromMap(map);

        final rule = config.get('level1.level2.level3');
        expect(rule, isNotNull);
        expect(rule!.name, 'DeepClass');
      });

      test('should handle mixed nesting levels', () {
        final map = {
          'type_definitions': {
            // Direct rule at root of types (uncommon but possible)
            'raw': {
              'name': 'RawType',
            },
            // Nested rule
            'nested': {
              'inner': {
                'name': 'InnerType',
              }
            }
          }
        };

        final config = TypeConfig.fromMap(map);

        expect(config.get('raw'), isNotNull);
        expect(config.get('raw')!.name, 'RawType');

        expect(config.get('nested.inner'), isNotNull);
        expect(config.get('nested.inner')!.name, 'InnerType');
      });

      test('should return null for unknown keys', () {
        final map = {
          'type_definitions': {
            'group': {'name': 'A'}
          }
        };
        final config = TypeConfig.fromMap(map);

        expect(config.get('unknown'), isNull);
        expect(config.get('group.unknown'), isNull);
      });

      test('should return empty config if type_definitions key is missing', () {
        final config = TypeConfig.fromMap({});
        expect(config.get('any'), isNull);
      });

      test('should ignore malformed entries (not maps)', () {
        final map = {
          'type_definitions': {
            'valid': {'name': 'A'},
            'invalid': 'not_a_map',
            'list_invalid': ['a', 'b']
          }
        };

        final config = TypeConfig.fromMap(map);
        expect(config.get('valid'), isNotNull);
        expect(config.get('invalid'), isNull);
      });
    });
  });
}