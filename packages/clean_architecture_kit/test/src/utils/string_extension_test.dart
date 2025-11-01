import 'package:clean_architecture_kit/src/utils/string_extension.dart';
import 'package:test/test.dart';

void main() {
  group('StringCaseUtils', () {
    group('toPascalCase', () {
      test('should convert camelCase to PascalCase', () {
        expect('getUser'.toPascalCase(), 'GetUser');
      });

      test('should handle single words', () {
        expect('user'.toPascalCase(), 'User');
      });

      test('should handle already PascalCased string', () {
        expect('GetUser'.toPascalCase(), 'GetUser');
      });

      test('should handle empty string', () {
        expect(''.toPascalCase(), '');
      });
    });

    group('toSnakeCase', () {
      test('should convert camelCase to snake_case', () {
        expect('getUser'.toSnakeCase(), 'get_user');
      });

      test('should convert PascalCase to snake_case', () {
        expect('GetUser'.toSnakeCase(), 'get_user');
      });

      test('should convert multi-word PascalCase', () {
        expect('GetUserById'.toSnakeCase(), 'get_user_by_id');
      });

      test('should handle single words', () {
        expect('User'.toSnakeCase(), 'user');
      });

      test('should handle empty string', () {
        expect(''.toSnakeCase(), '');
      });
    });
  });
}
