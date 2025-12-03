import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('MapExtensions', () {
    group('getString', () {
      test('should return the string value when key exists and is a String', () {
        final map = {'key': 'value'};
        expect(map.getString('key'), 'value');
      });

      test('should return empty string by default when key is missing', () {
        final map = {'other': 'value'};
        expect(map.getString('missing_key'), '');
      });

      test('should return provided fallback when key is missing', () {
        final map = {'other': 'value'};
        expect(map.getString('missing_key', fallback: 'default'), 'default');
      });

      test('should return fallback when value is not a String', () {
        final map = {'key': 123}; // Integer value
        expect(map.getString('key', fallback: 'default'), 'default');
      });
    });

    group('tryGetString', () {
      test('should return the string value when key exists', () {
        final map = {'key': 'value'};
        expect(map.tryGetString('key'), 'value');
      });

      test('should return null by default when key is missing', () {
        final map = {'other': 'value'};
        expect(map.tryGetString('missing_key'), isNull);
      });

      test('should return fallback when key is missing', () {
        final map = {'other': 'value'};
        expect(map.tryGetString('missing_key', fallback: 'fb'), 'fb');
      });

      test('should return null when value is wrong type', () {
        final map = {'key': true};
        expect(map.tryGetString('key'), isNull);
      });
    });

    group('getBool', () {
      test('should return true when value is true', () {
        final map = {'flag': true};
        expect(map.getBool('flag'), isTrue);
      });

      test('should return false when value is false', () {
        final map = {'flag': false};
        expect(map.getBool('flag'), isFalse);
      });

      test('should return false by default when key is missing', () {
        final map = {};
        expect(map.getBool('flag'), isFalse);
      });

      test('should return provided fallback when key is missing', () {
        final map = {};
        expect(map.getBool('flag', fallback: true), isTrue);
      });

      test('should return fallback when value is not a boolean', () {
        final map = {'flag': 'true'}; // String "true", not boolean true
        expect(map.getBool('flag', fallback: false), isFalse);
      });
    });

    group('getStringList', () {
      test('should return a list of strings when value is a List<String>', () {
        final map = {
          'items': ['a', 'b'],
        };
        expect(map.getStringList('items'), ['a', 'b']);
      });

      test('should return a list of strings when value is a List<dynamic>', () {
        final map = {
          'items': ['a', 'b'],
        };
        expect(map.getStringList('items'), ['a', 'b']);
      });

      test('should filter out non-string elements from mixed list', () {
        final map = {
          'items': ['a', 123, true, 'b'],
        };
        expect(map.getStringList('items'), ['a', 'b']);
      });

      test('should wrap a single string value into a list', () {
        final map = {'items': 'single_value'};
        expect(map.getStringList('items'), ['single_value']);
      });

      test('should return empty list when key is missing', () {
        final map = {};
        expect(map.getStringList('items'), isEmpty);
      });

      test('should return empty list when value is not a list or string', () {
        final map = {'items': 123};
        expect(map.getStringList('items'), isEmpty);
      });
    });

    group('getMap', () {
      test('should return the map when value is a Map<String, dynamic>', () {
        final map = {
          'config': {'a': 1},
        };
        final result = map.getMap('config');
        expect(result, isA<Map<String, dynamic>>());
        expect(result['a'], 1);
      });

      test('should correctly cast Map<dynamic, dynamic> (Simulating YamlMap)', () {
        // This mimics exactly what loadYaml returns
        final dynamicMap = <dynamic, dynamic>{'a': 1, 'b': 'hello'};
        final map = {'config': dynamicMap};

        final result = map.getMap('config');

        expect(result, isA<Map<String, dynamic>>());
        expect(result['a'], 1);
        expect(result['b'], 'hello');
      });

      test('should return empty map when key is missing', () {
        final map = {};
        expect(map.getMap('config'), isEmpty);
      });

      test('should return empty map when value is not a Map', () {
        final map = {'config': 'not_a_map'};
        expect(map.getMap('config'), isEmpty);
      });
    });
  });
}
