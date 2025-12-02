import 'package:architecture_lints/src/utils/naming_utils.dart';
import 'package:test/test.dart';

void main() {
  group('NamingUtils', () {
    group('validate ({{name}} placeholder)', () {
      const template = '{{name}}';

      test('should pass for standard PascalCase', () {
        expect(NamingUtils.validate(name: 'User', template: template), isTrue);
        expect(NamingUtils.validate(name: 'AuthService', template: template), isTrue);
        expect(NamingUtils.validate(name: 'APIClient', template: template), isTrue);
      });

      test('should pass for PascalCase with numbers', () {
        expect(NamingUtils.validate(name: 'User1', template: template), isTrue);
        expect(NamingUtils.validate(name: 'V1Controller', template: template), isTrue);
      });

      test('should fail for camelCase', () {
        expect(NamingUtils.validate(name: 'user', template: template), isFalse);
        expect(NamingUtils.validate(name: 'authService', template: template), isFalse);
      });

      test('should fail for snake_case', () {
        expect(NamingUtils.validate(name: 'user_entity', template: template), isFalse);
      });
    });

    group('validate (Suffixes & Prefixes)', () {
      test('should enforce strict suffixes', () {
        const template = '{{name}}Repository';

        expect(NamingUtils.validate(name: 'AuthRepository', template: template), isTrue);

        // Fail: Missing suffix
        expect(NamingUtils.validate(name: 'Auth', template: template), isFalse);
        // Fail: Wrong suffix
        expect(NamingUtils.validate(name: 'AuthService', template: template), isFalse);
        // Fail: Extra characters after suffix (regex uses $)
        expect(NamingUtils.validate(name: 'AuthRepositoryImpl', template: template), isFalse);
      });

      test('should enforce strict prefixes', () {
        const template = 'I{{name}}';

        expect(NamingUtils.validate(name: 'IAuth', template: template), isTrue);

        // Fail: Missing prefix
        expect(NamingUtils.validate(name: 'Auth', template: template), isFalse);
        // Fail: Wrong case prefix
        expect(NamingUtils.validate(name: 'iAuth', template: template), isFalse);
      });
    });

    group('validate ({{affix}} placeholder)', () {
      test('should allow prefixes via affix', () {
        const template = '{{affix}}Repository';

        expect(NamingUtils.validate(name: 'RemoteAuthRepository', template: template), isTrue);
        expect(NamingUtils.validate(name: 'CachedRepository', template: template), isTrue);

        // Affix is wildcard, so empty string usually matches unless strict
        expect(NamingUtils.validate(name: 'Repository', template: template), isTrue);
      });

      test('should allow suffixes via affix', () {
        const template = 'User{{affix}}';

        expect(NamingUtils.validate(name: 'UserDetail', template: template), isTrue);
        expect(NamingUtils.validate(name: 'UserForm', template: template), isTrue);
        expect(NamingUtils.validate(name: 'User', template: template), isTrue);
      });

      test('should handle middle placeholders', () {
        const template = '{{name}}State{{affix}}';

        expect(NamingUtils.validate(name: 'LoginState', template: template), isTrue);
        expect(NamingUtils.validate(name: 'LoginStateSuccess', template: template), isTrue);
        expect(NamingUtils.validate(name: 'LoginStateFailure', template: template), isTrue);

        // Fail: "State" part is missing
        expect(NamingUtils.validate(name: 'LoginSuccess', template: template), isFalse);
      });
    });

    group('Caching Behavior', () {
      test('should return consistent results on multiple calls', () {
        const template = '{{name}}Cached';

        // First call (populates cache)
        expect(NamingUtils.validate(name: 'UserCached', template: template), isTrue);
        // Second call (hits cache)
        expect(NamingUtils.validate(name: 'UserCached', template: template), isTrue);
      });
    });
  });
}
