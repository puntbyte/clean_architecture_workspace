// example/lib/features/auth/data/model/user_model.dart

import 'package:example/features/auth/domain/entities/user_entity.dart';

// A compliant model.
// Its name `UserModel` matches the `{{name}}Model` convention.
class UserModel extends UserEntity {
  //final String id; // not necessary
  //final String name; // not necessary

  //const UserModel({required this.id, required this.name}) : super(id: id, name: name);

  const UserModel({required super.id, required super.name}); // better way


// The mapping logic that converts the "impure" Model to a "pure" Entity.
  // expected toEntity() method when using quick fix
  UserEntity toEntity() {
    return UserEntity(id: id, name: name);
  }
}
