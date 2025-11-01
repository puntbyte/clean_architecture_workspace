// VIOLATION: data_source_purity (importing a pure domain Entity)
import '../../domain/entities/user.dart';

// VIOLATION: enforce_naming_conventions (name does not match the '{{name}}DataSource' template)
abstract interface class AuthRemoteDS {
  // <-- LINT WARNING HERE
  // VIOLATION: data_source_purity (should return UserModel, not the pure User entity)
  Future<User> getEntity(int id); // <-- LINT WARNING HERE
}

// VIOLATION: enforce_naming_conventions (name does not match the 'Default{{name}}DataSource'
// template)
class AuthRemoteDataSourceImpl implements AuthRemoteDS {
  // <-- LINT WARNING HERE
  @override
  Future<User> getEntity(int id) => throw UnimplementedError();
}
