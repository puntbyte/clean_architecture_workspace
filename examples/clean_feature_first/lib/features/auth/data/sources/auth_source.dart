// example/lib/features/auth/data/sources/auth_source.dart

import 'package:clean_feature_first/core/source/source.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/models/user_model.dart';

// CORRECT:
// 1. Name matches `{{name}}Source`.
// 2. Implements `Source` (from core).
abstract interface class AuthSource implements Source {

  // CORRECT:
  // 1. Returns raw `Future<UserModel>` (not FutureEither, not Entity).
  // 2. Uses `StringId` (Strong Type) for ID parameter.
  Future<UserModel> getUser(StringId id);

  Future<void> cacheUser(UserModel user);
}