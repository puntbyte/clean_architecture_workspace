// lib/features/auth/domain/usecases/logout.dart

import 'package:clean_feature_first/core/error/failures.dart';
import 'package:clean_feature_first/core/usecase/usecase.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

@Injectable()
class Logout implements NullaryUsecase<void> {
  const Logout(this._repository);

  final AuthPort _repository;

  @override
  Future<Either<Failure, void>> call() => _repository.logout();
}
