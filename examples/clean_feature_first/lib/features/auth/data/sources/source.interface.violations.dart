// example/lib/features/auth/data/sources/source.interface.violations.dart

import 'package:clean_feature_first/core/source/source.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/data/models/user_model.dart';

// LINT: [1] arch_dep_component
// REASON: Data layer must deal with Models (DTOs), not pure Entities.
import 'package:clean_feature_first/features/auth/domain/entities/user.dart'; //! <-- LINT WARNING

// LINT: [2] arch_naming_pattern
// REASON: Name must match `{{name}}Source` (e.g., AuthSource).
abstract interface class AuthRemoteService implements Source { //! <-- LINT WARNING

  // LINT: [3] enforce_exception_on_data_source
  // REASON: DataSources must return raw Futures/Data. Wrappers (Either) imply
  // error handling logic which belongs in the Repository.
  FutureEither<UserModel> login(); //! <-- LINT WARNING

  // LINT: [4] arch_dep_component
  // REASON: Returning an Entity directly from a Source prevents the Repository from handling the
  // mapping logic.
  Future<User> fetchUser(); //! <-- LINT WARNING

  // LINT: [5] enforce_type_safety
  // REASON: Parameter 'id' must be `IntId`, not primitive `int`.
  Future<UserModel> getById(int id); //! <-- LINT WARNING
}

// LINT: [6] enforce_source_contract
// REASON: Source interfaces must implement the base `Source` interface from core.
abstract interface class UncontractedSource { //! <-- LINT WARNING
  Future<void> doWork();
}