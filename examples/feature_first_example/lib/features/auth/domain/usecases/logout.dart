import 'dart:async';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/src/either.dart';

final class Logout implements NullaryUsecase<void> {
  const Logout(this._repository);

  final AuthPort _repository;

  @override
  Future<Either<Failure, void>> call() => _repository.logout();
}
