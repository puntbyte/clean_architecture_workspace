// example/lib/features/auth/data/sources/auth_remote_data_source.violations.dart

// VIOLATION: disallow_entity_in_data_source (importing a pure domain Entity)
import "package:example/features/auth/domain/entities/user_entity.dart";

// VIOLATION: enforce_naming_conventions (name does not match the '{{name}}DataSource' template)
abstract interface class AuthRemoteDS { // <-- LINT WARNING HERE
  // VIOLATION: disallow_entity_in_data_source (should return UserModel, not the pure User entity)
  Future<UserEntity> getEntity(int id); // <-- LINT WARNING HERE
}

// VIOLATION: enforce_naming_conventions (name does not match the 'Default{{name}}DataSource' template)
class AuthRemoteDataSourceImpl implements AuthRemoteDS { // <-- LINT WARNING HERE
  @override
  Future<UserEntity> getEntity(int id) => throw UnimplementedError();
}
