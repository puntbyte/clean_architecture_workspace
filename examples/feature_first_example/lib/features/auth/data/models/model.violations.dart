// example/lib/features/auth/data/models/model.violations.dart
import 'package:example/features/auth/domain/entities/user.dart';

// LINT: enforce_model_inherits_entity
// Reason: Models must inherit from their corresponding entity.
class OrphanUserModel {
  final String id;
  OrphanUserModel(this.id);

  User toEntity() => User(id: id, username: 'Guest');
}

// LINT: enforce_model_to_entity_mapping
// Reason: Missing `toEntity()` method.
class LazyUserModel extends User {
  LazyUserModel({required super.id, required super.username});
}

// VIOLATION: enforce_model_inherits_entity
// The model `OrphanUserModel` does not extend or implement `UserEntity`.
class OrphanUserModel { // <-- LINT WARNING HERE
  final String id;
  final String name;
  final String email; // An extra field that the entity doesn't have.

  const OrphanUserModel({required this.id, required this.name, required this.email});

  // It has the toEntity() method, so it passes that lint...
  UserEntity toEntity() => UserEntity(id: id, names: name);
  // ...but it fails the inheritance check.
}


// VIOLATION: enforce_model_to_entity_mapping
// This model is correctly named but is missing the required `toEntity()` method.
class IncompleteUserModel extends UserEntity { // <-- LINT WARNING HERE (different lint)
  const IncompleteUserModel({required super.id, required super.name});
  // Missing the `toEntity()` method.
}

// VIOLATION: enforce_naming_conventions
// This model has the correct method, but its name violates the `{{name}}Model` convention.
class UserData extends UserEntity { // <-- LINT WARNING HERE (different lint)
  const UserData({required super.id, required super.name});
  UserEntity toEntity() => UserEntity(id: id, names: names);
}
