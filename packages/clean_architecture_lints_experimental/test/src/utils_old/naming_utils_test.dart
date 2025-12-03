// test/src/utils/naming_utils_test.dart

import 'package:architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  group('NamingUtils', () {
    group('getExpectedUseCaseClassName', () {
      test('should create correct class name when template is a simple {{name}}', () {
        final config = makeConfig(namingRules: [{'on': 'usecase', 'pattern': '{{name}}'}]);
        final result = NamingUtils.getExpectedUseCaseClassName('getUser', config);
        expect(result, 'GetUser');
      });

      test('should create correct class name when template has a suffix', () {
        final config = makeConfig(namingRules: [{'on': 'usecase', 'pattern': '{{name}}Action'}]);
        final result = NamingUtils.getExpectedUseCaseClassName('getUser', config);
        expect(result, 'GetUserAction');
      });

      test('should create correct class name when template has a prefix', () {
        final config = makeConfig(namingRules: [{'on': 'usecase', 'pattern': 'Do{{name}}'}]);
        final result = NamingUtils.getExpectedUseCaseClassName('getUser', config);
        expect(result, 'DoGetUser');
      });
    });

    group('validateName', () {
      // Test Case: {{name}}
      test('should return true for valid PascalCase names when template is {{name}}', () {
        expect(NamingUtils.validateName(name: 'User', template: '{{name}}'), isTrue);
        expect(NamingUtils.validateName(name: 'AuthService', template: '{{name}}'), isTrue);
      });

      test('should return false for non-PascalCase names when template is {{name}}', () {
        expect(NamingUtils.validateName(name: 'user', template: '{{name}}'), isFalse);
        expect(NamingUtils.validateName(name: '_User', template: '{{name}}'), isFalse);
      });

      // Test Case: Suffixes
      test('should return true when name has the correct suffix', () {
        expect(NamingUtils.validateName(name: 'UserModel', template: '{{name}}Model'), isTrue);
      });

      test('should return false when name is missing the required suffix', () {
        expect(NamingUtils.validateName(name: 'User', template: '{{name}}Model'), isFalse);
      });

      // Test Case: {{kind}}{{name}}
      test('should return true for a standard {{kind}}{{name}} pattern', () {
        expect(
          NamingUtils.validateName(name: 'DefaultAuthRepository', template: '{{kind}}{{name}}Repository'),
          isTrue,
        );
      });

      test('should return true for a multi-word kind in a {{kind}}{{name}} pattern', () {
        expect(
          NamingUtils.validateName(name: 'FirebaseAuthRepository', template: '{{kind}}{{name}}Repository'),
          isTrue,
        );
      });

      test('should return false when kind is missing in a {{kind}}{{name}} pattern', () {
        // The non-greedy `kind` matches nothing, and the greedy `name` consumes "Auth".
        // The regex fails because the `name` token must match at least one character.
        // This is subtle, but correct behavior. A better test is to check if it's just one word.
        expect(
          NamingUtils.validateName(name: 'AuthRepository', template: '{{kind}}{{name}}Repository'),
          isFalse,
        );
      });

      // Test Case: Special Characters and Complex Templates
      test('should return true when template contains leading underscores', () {
        expect(NamingUtils.validateName(name: '_GetUserParams', template: '_{{name}}Params'), isTrue);
      });

      test('should return false when template literals do not match', () {
        expect(NamingUtils.validateName(name: 'GetUserParams', template: '_{{name}}Params'), isFalse);
      });

      test('should return true for templates with multiple placeholders', () {
        expect(NamingUtils.validateName(name: 'Remote_AuthEvent', template: '{{kind}}_{{name}}Event'), isTrue);
      });
    });
  });
}
