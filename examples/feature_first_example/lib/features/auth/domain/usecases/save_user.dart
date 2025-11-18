import 'package:example/core/usecase/usecase.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

typedef _SaveUserParams = ({
  String name,
  String password,
});

final class SaveUser implements UnaryUsecase<void, _SaveUserParams> {
  final AuthRepository _repository;

  const SaveUser(this._repository);

  @override
  Future<Either<Failure, void>> call(_SaveUserParams params) {
    return _repository.saveUser(name: params.name, password: params.password);
  }
}
