import 'package:example/core/usecase/usecase.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/entities/user.dart';
import 'package:example/features/auth/domain/ports/auth_port.dart';

// CORRECT: Extends UnaryUsecase, Semantic name (Verb+Noun).
class LoginUser implements UnaryUsecase<User, ({String user, String pass})> {
  final AuthRepository _repository;

  const LoginUser(this._repository);

  @override
  FutureEither<User> call(({String user, String pass}) params) {
    return _repository.login(params.user, params.pass);
  }
}