import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/data/sources/auth_remote_data_source.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:example/features/auth/domain/entities/user_entity.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  const AuthRepositoryImpl(this._remoteDataSource);

  @override
  FutureEither<UserEntity> getUser(int id) async {
    return Right(UserEntity(id: '1', name: 'test'));
  }

  @override
  FutureEither<void> saveUser({required String name, required String password}) async {
    return const Right(null);
  }

  @override
  FutureEither<UserEntity?> getCurrentUser() async => const Right(null);
}
