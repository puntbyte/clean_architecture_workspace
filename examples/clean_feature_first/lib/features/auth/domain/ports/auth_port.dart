// lib/features/auth/domain/ports/auth_port.dart

import 'package:clean_feature_first/core/port/port.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';

// Extends Port, returns FutureEither, naming is correct.
abstract interface class AuthPort implements Port {
  FutureEither<User> login(String username, String password);


  FutureEither<User> currentUser(IntId id);

  FutureEither<void> logout();
}
