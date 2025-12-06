// lib/features/auth/domain/usecases/request_logout.dart

import 'package:clean_feature_first/core/usecase/usecase.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:injectable/injectable.dart';

@Injectable()
class RequestLogout implements NullaryUsecase<void> {
  const RequestLogout(this._repository);

  final AuthPort _repository;

  @override
  FutureEither<void> call() => _repository.logout();
}
