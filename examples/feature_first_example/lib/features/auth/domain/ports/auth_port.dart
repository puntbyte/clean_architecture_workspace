// lib/features/auth/domain/ports/auth_port.dart

import 'package:example/core/repository/repository.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/entities/user.dart';

// CORRECT: Extends Port, returns FutureEither, naming is correct.
abstract interface class AuthPort implements Repository {
  FutureEither<User> login(String username, String password);
  FutureEither<void> logout();
}

