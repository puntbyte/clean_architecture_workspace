// test/src/utils/extensions/json_map_extension_test.dart

import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';
import 'package:test/test.dart';

void main() {
  group('JsonMapExtension', () {
    group('asBool', () {
      test('should return true when value is true', () {
        final json = {'enabled': true};
        expect(json.asBool('enabled'), isTrue);
      });

      test('should return false when value is false', () {
        final json = {'enabled': false};
        expect(json.asBool('enabled'), isFalse);
      });

      test('should return default false when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asBool('enabled'), isFalse);
      });

      test('should return custom orElse when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asBool('enabled', orElse: true), isTrue);
      });

      test('should return orElse for non-boolean values', () {
        final json = {'enabled': 'not_a_bool'};
        expect(json.asBool('enabled', orElse: true), isTrue);
      });

      test('should return orElse for null values', () {
        final json = <String, dynamic>{'enabled': null};
        expect(json.asBool('enabled', orElse: true), isTrue);
      });
    });

    group('asString', () {
      test('should return string value when it exists', () {
        final json = {'name': 'my_app'};
        expect(json.asString('name'), 'my_app');
      });

      test('should return empty string when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asString('name'), '');
      });

      test('should return custom orElse when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asString('name', orElse: 'default'), 'default');
      });

      test('should return orElse for non-string values', () {
        final json = {'name': 123};
        expect(json.asString('name', orElse: 'default'), 'default');
      });

      test('should return orElse for null values', () {
        final json = <String, dynamic>{'name': null};
        expect(json.asString('name', orElse: 'default'), 'default');
      });
    });

    group('asStringOrNull', () {
      test('should return string value when it exists', () {
        final json = {'path': '/lib/core'};
        expect(json.asStringOrNull('path'), '/lib/core');
      });

      test('should return null when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asStringOrNull('path'), isNull);
      });

      test('should return null for non-string values', () {
        final json = {'path': 123};
        expect(json.asStringOrNull('path'), isNull);
      });

      test('should return null for explicit null values', () {
        final json = <String, dynamic>{'path': null};
        expect(json.asStringOrNull('path'), isNull);
      });
    });

    group('asStringList', () {
      test('should return list of strings when value is a valid list', () {
        final json = {
          'items': ['a', 'b'],
        };
        expect(json.asStringList('items'), ['a', 'b']);
      });

      test('should return list containing the string for a single string value', () {
        final json = {'items': 'a'};
        expect(json.asStringList('items'), ['a']);
      });

      test('should return empty list when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asStringList('items'), isEmpty);
      });

      test('should return custom orElse when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asStringList('items', orElse: ['default']), ['default']);
      });

      test('should return orElse for non-list and non-string values', () {
        final json = {'items': 123};
        expect(json.asStringList('items', orElse: ['default']), ['default']);
      });

      test('should return orElse for lists with non-string items', () {
        final json = {
          'items': ['a', 123, 'b'],
        };
        expect(json.asStringList('items', orElse: ['default']), ['default']);
      });

      test('should return empty list for explicit null value', () {
        final json = <String, dynamic>{'items': null};
        expect(json.asStringList('items'), isEmpty);
      });
    });

    group('asMap', () {
      test('should return JsonMap when value is a valid JsonMap', () {
        final json = {
          'config': {'key': 'value'},
        };
        expect(json.asMap('config'), {'key': 'value'});
      });

      test('should convert Map<dynamic, dynamic> to JsonMap', () {
        final json = <String, dynamic>{
          'config': <dynamic, dynamic>{'key': 'value'},
        };
        expect(json.asMap('config'), {'key': 'value'});
      });

      test('should return empty map when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asMap('config'), isEmpty);
      });

      test('should return custom orElse when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asMap('config', orElse: {'default': 'value'}), {'default': 'value'});
      });

      test('should return orElse for non-map values', () {
        final json = {'config': 'not_a_map'};
        expect(json.asMap('config', orElse: {'default': 'value'}), {'default': 'value'});
      });

      test('should return orElse for null values', () {
        final json = <String, dynamic>{'config': null};
        expect(json.asMap('config', orElse: {'default': 'value'}), {'default': 'value'});
      });

      test('should handle nested map retrieval', () {
        final json = {
          'outer': {
            'inner': {'value': 42},
          },
        };
        final outer = json.asMap('outer');
        expect(outer.asMap('inner'), {'value': 42});
      });
    });

    group('asMapList', () {
      test('should return list of JsonMap for a valid list of maps', () {
        final json = {
          'rules': [
            {'name': 'rule1'},
            {'name': 'rule2'},
          ],
        };
        final result = json.asMapList('rules');
        expect(result, hasLength(2));
        expect(result.first['name'], 'rule1');
        expect(result.last['name'], 'rule2');
      });

      test('should return empty list when key is missing', () {
        final json = {'other': 'value'};
        expect(json.asMapList('rules'), isEmpty);
      });

      test('should return custom orElse when key is missing', () {
        final json = {'other': 'value'};
        final defaultList = [
          {'default': 'rule'},
        ];
        expect(json.asMapList('rules', orElse: defaultList), defaultList);
      });

      test('should return empty list for null value', () {
        final json = <String, dynamic>{'rules': null};
        expect(json.asMapList('rules'), isEmpty);
      });

      test('should filter out non-map items from list', () {
        final json = {
          'rules': [
            {'name': 'rule1'},
            'not_a_map',
            123,
            {'name': 'rule2'},
          ],
        };
        final result = json.asMapList('rules');
        expect(result, hasLength(2));
        expect(result.first['name'], 'rule1');
        expect(result.last['name'], 'rule2');
      });

      test('should return orElse for non-list values', () {
        final json = {'rules': 'not_a_list'};
        expect(
          json.asMapList(
            'rules',
            orElse: [
              {'default': 'value'},
            ],
          ),
          [
            {'default': 'value'},
          ],
        );
      });

      test('should handle empty list', () {
        final json = {'rules': List<dynamic>.empty()};
        expect(json.asMapList('rules'), isEmpty);
      });
    });
  });
}
