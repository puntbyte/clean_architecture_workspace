// example/lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/data/sources/auth_remote_data_source.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
<<<<<<<< HEAD:examples/feature_first_example/lib/features/auth/data/repositories/auth_repository_imp.dart
import 'package:example/features/auth/domain/entities/user.dart';
========
import 'package:example/features/auth/domain/entities/entities.violations.dart';
import 'package:example/features/auth/domain/entities/user.dart' hide User;
import 'package:example/features/auth/domain/entities/user_entity.dart';
>>>>>>>> origin/master:examples/feature_first_example/lib/features/auth/data/repositories/default_auth_repository.dart
import 'package:fpdart/fpdart.dart';

class DefaultAuthRepository implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  const DefaultAuthRepository(this._remoteDataSource);
  @override
  FutureEither<UserEntity> getUser(int id) {
    return Right(User(id: '1', name: 'test'));
  }

  @override
  FutureEither<UserEntity> getUser() async {

  }

  @override
  FutureEither<void> saveUser({required String name, required String password}) async {
    return const Right(null);
  }

  @override
  FutureEither<UserEntity?> getCurrentUser() async => const Right(null);
}
