// example/lib/features/auth/data/model/user_model.dart

import 'package:example/features/auth/domain/entities/user_entity.dart';

// A compliant model.
// Its name `UserModel` matches the `{{name}}Model` convention.
class UserModel extends UserEntity {
  final String id;
  final String name;

  const UserModel({required this.id, required this.name})
      : super(id: id, name: name);

  // The mapping logic that converts the "impure" Model to a "pure" Entity.
  UserEntity toEntity() => UserEntity(id: id, name: name);
}
