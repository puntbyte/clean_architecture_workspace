// example/lib/features/auth/data/sources/source.interface.violations.dart

import 'package:clean_feature_first/core/source/source.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/models/user_model.dart';

// lint: [1] arch_dep_component
// reason: Data layer must deal with Models (DTOs), not pure Entities.
import 'package:clean_feature_first/features/auth/domain/entities/user.dart'; //! <-- LINT WARNING

// lint: [2] arch_naming_pattern
// reason: Name must match `{{name}}Source` (e.g., AuthSource).
abstract interface class AuthRemoteService implements Source { //! <-- LINT WARNING

  // lint: [3] arch_safety_return_forbidden
  // reason: DataSources must return raw Futures/Data. Wrappers (Either) imply error handling logic
  // which belongs in the Repository.
  FutureEither<UserModel> login(); //! <-- LINT WARNING

  // lint: [4] arch_dep_component
  // reason: Returning an Entity directly from a Source prevents the Repository from handling the
  // mapping logic.
  Future<User> fetchUser(); //! <-- LINT WARNING

  // lint: [5] arch_safety_param_forbidden
  // reason: Parameter 'id' must be `IntId`, not primitive `int`.
  Future<UserModel> getById(int id); //! <-- LINT WARNING
}

// lint: [6] arch_type_missing_base
// reason: Source interfaces must implement the base `Source` interface from core.
// ignore: arch_naming_grammar
abstract interface class UncontractedSource { //! <-- LINT WARNING
  Future<void> doWork();
}