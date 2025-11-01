import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:test/test.dart';

CleanArchitectureConfig makeTestConfig(String useCaseTemplate) {
  return CleanArchitectureConfig.fromMap({
    'naming_conventions': {'use_case': useCaseTemplate},
  });
}

void main() {
  group('NamingUtils', () {
    group('getExpectedUseCaseClassName', () {
      test('should apply a suffix template correctly', () {
        final config = makeTestConfig('{{name}}Usecase');
        expect(NamingUtils.getExpectedUseCaseClassName('getUser', config), 'GetUserUsecase');
      });

      test('should apply a prefix template correctly', () {
        final config = makeTestConfig('UC{{name}}');
        expect(NamingUtils.getExpectedUseCaseClassName('getUser', config), 'UCGetUser');
      });

      test('should handle a no-op template correctly', () {
        final config = makeTestConfig('{{name}}');
        expect(NamingUtils.getExpectedUseCaseClassName('getUser', config), 'GetUser');
      });
    });

    group('validateName', () {
      test('should return true for a valid suffix template match', () {
        expect(
          NamingUtils.validateName(name: 'GetUserUsecase', template: '{{name}}Usecase'),
          isTrue,
        );
      });

      test('should return false for an invalid suffix template match', () {
        expect(NamingUtils.validateName(name: 'GetUser', template: '{{name}}Usecase'), isFalse);
      });

      test('should return true for a valid regex template match', () {
        expect(
          NamingUtils.validateName(
            name: 'AuthRepositoryImpl',
            template: '{{name}}(Impl|RepositoryImpl)',
          ),
          isTrue,
        );
      });

      test('should return false for an invalid regex template match', () {
        expect(
          NamingUtils.validateName(
            name: 'AuthRepositoryImplementation',
            template: '{{name}}(Impl|RepositoryImpl)',
          ),
          isFalse,
        );
      });
    });
  });
}
