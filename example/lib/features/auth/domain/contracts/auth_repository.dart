// example/lib/features/auth/domain/contracts/auth_repository.dart

import '../../../../core/repository/repository.dart';
import '../../../../core/utils/types.dart';
import '../entities/user_entity.dart';

abstract interface class AuthRepository implements Repository {
  // LINT INFO: missing_use_case (Quick Fix is available here)
  FutureEither<UserEntity> getUser(int id);

  // LINT INFO: missing_use_case (Quick Fix is available here)
  FutureEither<void> saveUser({required String name, required String password});

  // This one has a corresponding use case file, so no lint will appear.
  FutureEither<UserEntity?> getCurrentUser();
}
