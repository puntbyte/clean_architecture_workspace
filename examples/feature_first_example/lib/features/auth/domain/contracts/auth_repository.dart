// example/lib/features/auth/domain/contracts/auth_repository.dart

import 'package:example/core/repository/repository.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/entities/user.dart';

abstract interface class AuthRepository implements Repository {
  // LINT INFO: missing_use_case (Quick Fix is available here)
  FutureEither<User> getUser(int id);

  // LINT INFO: missing_use_case (Quick Fix is available here)
  FutureEither<void> saveUser({required String name, required String password});

  // This one has a corresponding use case file, so no lint will appear.
  FutureEither<User?> getCurrentUser();
}
