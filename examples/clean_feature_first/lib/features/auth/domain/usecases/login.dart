// lib/features/auth/domain/usecases/login.dart

import 'dart:async';
import 'package:clean_feature_first/core/error/failures.dart';
import 'package:clean_feature_first/core/usecase/usecase.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/src/either.dart';
import 'package:injectable/injectable.dart';

typedef _LoginParams = ({String username, String password});

@Injectable()
class Login implements UnaryUsecase<User, _LoginParams> {
  const Login(this._repository);

  final AuthPort _repository;

  @override
  Future<Either<Failure, User>> call(_LoginParams params) =>
      _repository.login(params.username, params.password);
}
