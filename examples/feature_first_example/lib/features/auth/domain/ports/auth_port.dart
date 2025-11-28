// lib/features/auth/domain/ports/auth_port.dart

import 'package:feature_first_example/core/port/port.dart';
import 'package:feature_first_example/core/utils/types.dart';
import 'package:feature_first_example/features/auth/domain/entities/user.dart';

// CORRECT: Extends Port, returns FutureEither, naming is correct.
abstract interface class AuthPort implements Port {
  FutureEither<User> login(String username, String password);
  FutureEither<void> logout();
}
