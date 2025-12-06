// lib/features/auth/domain/usecases/request_login.dart

import 'package:clean_feature_first/core/usecase/usecase.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:injectable/injectable.dart';

typedef _LoginParams = ({String username, String password});

@Injectable()
class RequestLogin implements UnaryUsecase<User, _LoginParams> {
  const RequestLogin(this._repository);

  final AuthPort _repository;

  @override
  FutureEither<User> call(_LoginParams params) =>
      _repository.login(params.username, params.password);
}
