import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';
import 'package:test/test.dart';

void main() {
  group('ConfigParsingExtension on Map<String, dynamic>', () {
    // --- Tests for getMap ---
    group('getMap', () {
      test('should return a map when the value is a valid map', () {
        final source = {
          'config': {'key': 'value', 'number': 123}
        };
        final result = source.getMap('config');
        expect(result, isA<Map<String, dynamic>>());
        expect(result, isNotEmpty);
        expect(result['key'], 'value');
      });

      test('should return an empty map when the key does not exist', () {
        final source = {'other_key': 'value'};
        final result = source.getMap('config');
        expect(result, isA<Map<String, dynamic>>());
        expect(result, isEmpty);
      });

      test('should return an empty map when the value is not a map', () {
        final source = {'config': 'not_a_map'};
        final result = source.getMap('config');
        expect(result, isA<Map<String, dynamic>>());
        expect(result, isEmpty);
      });

      test('should return an empty map when the value is null', () {
        final source = <String, dynamic>{'config': null};
        final result = source.getMap('config');
        expect(result, isA<Map<String, dynamic>>());
        expect(result, isEmpty);
      });
    });

    // --- Tests for getList ---
    group('getList', () {
      test('should return a list of strings when the value is a valid list', () {
        final source = {
          'directories': ['entities', 'repositories']
        };
        final result = source.getList('directories');
        expect(result, isA<List<String>>());
        expect(result, hasLength(2));
        expect(result, equals(['entities', 'repositories']));
      });

      test('should return an empty list when the key does not exist', () {
        final source = {'other_key': 'value'};
        final result = source.getList('directories');
        expect(result, isA<List<String>>());
        expect(result, isEmpty);
      });

      test('should return an empty list when the value is not a list', () {
        final source = {'directories': {'not': 'a list'}};
        final result = source.getList('directories');
        expect(result, isA<List<String>>());
        expect(result, isEmpty);
      });

      test('should return an empty list when the value is null', () {
        final source = <String, dynamic>{'directories': null};
        final result = source.getList('directories');
        expect(result, isA<List<String>>());
        expect(result, isEmpty);
      });

      test('should filter out non-string elements from a mixed list', () {
        final source = {
          'directories': ['entities', 123, null, 'repositories', true]
        };
        final result = source.getList('directories');
        expect(result, isA<List<String>>());
        expect(result, hasLength(2));
        expect(result, equals(['entities', 'repositories']));
      });
    });

    // --- Tests for getString ---
    group('getString', () {
      test('should return the string value when it exists', () {
        final source = {'name': 'my_app'};
        final result = source.getString('name', orElse: 'default');
        expect(result, 'my_app');
      });

      test('should return the orElse value when the key does not exist', () {
        final source = {'other_key': 'value'};
        final result = source.getString('name', orElse: 'default');
        expect(result, 'default');
      });

      test('should return the orElse value when the value is not a string', () {
        final source = {'name': 12345};
        final result = source.getString('name', orElse: 'default');
        expect(result, 'default');
      });

      test('should return the orElse value when the value is null', () {
        final source = <String, dynamic>{'name': null};
        final result = source.getString('name', orElse: 'default');
        expect(result, 'default');
      });

      test('should return the default orElse value (empty string) if not provided', () {
        final source = {'name': 123};
        final result = source.getString('name');
        expect(result, '');
      });
    });
  });
}
