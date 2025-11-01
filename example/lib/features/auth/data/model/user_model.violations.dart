import 'package:example/features/auth/domain/entities/user_entity.dart';

// VIOLATION: enforce_naming_conventions
// The class name `UserData` does not match the configured format: `{{name}}Model`.
class UserData { // <-- LINT WARNING HERE
  final String id;
  final String name;

  const UserData({required this.id, required this.name});

  // This class has the correct mapping logic, but its name is what
  // violates the architectural rule.
  UserEntity toEntity() => UserEntity(id: id, name: name);
}
