// example/lib/features/auth/domain/contracts/auth_repository.violations.dart

import 'package:example/core/repository/repository.dart';
import 'package:example/core/utils/types.dart';
// VIOLATION: enforce_layer_independence (importing from the data layer)
import 'package:example/features/auth/data/model/user_model.dart';
import 'package:example/features/auth/domain/entities/user_entity.dart';


// VIOLATION: enforce_repository_inheritance (does not extend Repository)
abstract interface class IAnalyticsRepository {
  void getUser(int id);
}

// VIOLATION: enforce_custom_return_type (returns Future<User> instead of FutureEither)
abstract interface class BadReturnTypeRepository implements Repository {
  Future<UserEntity> getUser(int id); // <-- LINT WARNING HERE
}

// VIOLATION: enforce_naming_conventions (name does not end with "Repository")
abstract interface class AuthRepo implements Repository {} // <-- LINT WARNING HERE

abstract interface class BadSignatureRepository implements Repository {
  // VIOLATION: domain_layer_purity (uses a Model in a return type)
  FutureEither<UserModel> getUser(int id); // <-- LINT ERROR HERE

  // VIOLATION: domain_layer_purity (uses a Model in a parameter)
  FutureEither<void> saveUser(UserModel user); // <-- LINT ERROR HERE
}
