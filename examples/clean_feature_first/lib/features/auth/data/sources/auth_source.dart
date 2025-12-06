// example/lib/features/auth/data/sources/auth_source.dart

import 'package:clean_feature_first/core/source/source.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/models/user_model.dart';

// Wrong: arch_type_missing_base
// Warning: The component "Data Source (Implementation)" is invalid. It must inherit from a class
// belonging to: Component(source.interface).
//
// Extend or implement one of the required types.
abstract interface class AuthSource implements Source {
  Future<UserModel> getUser(StringId id);

  Future<void> cacheUser(UserModel user);
}