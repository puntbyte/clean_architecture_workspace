// lib/features/auth/domain/usecases/login.dart

import 'dart:async';
import 'package:feature_first_example/core/usecase/usecase.dart';
import 'package:feature_first_example/core/utils/types.dart';
import 'package:feature_first_example/features/auth/domain/entities/user.dart';
import 'package:feature_first_example/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/src/either.dart';

typedef _LoginParams = ({String username, String password});

final class Login implements UnaryUsecase<User, _LoginParams> {
  const Login(this._repository);

  final AuthPort _repository;

  @override
  Future<Either<Failure, User>> call(_LoginParams params) =>
      _repository.login(params.username, params.password);
}
