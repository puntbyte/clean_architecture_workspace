import 'package:example/core/usecase/usecase.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/types.dart';
import '../contracts/auth_repository.dart';
import '../entities/user_entity.dart';

@Injectable()
final class GetCurrentUserUsecase implements NullaryUsecase<UserEntity?> {
  const GetCurrentUserUsecase(this.repository);

  final AuthRepository repository;

  @override
  FutureEither<UserEntity?> call() => repository.getCurrentUser();
}
