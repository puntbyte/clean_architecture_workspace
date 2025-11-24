import 'package:example/core/usecase/usecase.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/types.dart';
import '../contracts/auth_port.dart';
import '../entities/user.dart';

@Injectable()
final class GetCurrentUserUsecase implements NullaryUsecase<UserEntity?> {
  const GetCurrentUserUsecase(this.repository);

  final AuthRepository repository;

  @override
  FutureEither<UserEntity?> call() => repository.getCurrentUser();
}
