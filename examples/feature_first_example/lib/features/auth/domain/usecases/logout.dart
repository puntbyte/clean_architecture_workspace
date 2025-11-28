// lib/features/auth/domain/usecases/logout.dart

import 'package:feature_first_example/core/usecase/usecase.dart';
import 'package:feature_first_example/core/utils/types.dart';
import 'package:feature_first_example/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/fpdart.dart';

final class Logout implements NullaryUsecase<void> {
  const Logout(this._repository);

  final AuthPort _repository;

  @override
  Future<Either<Failure, void>> call() => _repository.logout();
}
