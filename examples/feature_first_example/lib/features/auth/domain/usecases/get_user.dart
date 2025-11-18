import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:example/features/auth/domain/entities/user.dart';
import 'package:injectable/injectable.dart';
import '/core/usecase/usecase.dart';

@Injectable()
final class GetUser implements UnaryUsecase<User, int> {
  const GetUser(this.repository);

  final AuthRepository repository;

  @override
  FutureEither<User> call(int id) => repository.getUser(id);
}
