// lib/features/auth/data/models/user_model.dart

import 'package:feature_first_example/features/auth/domain/entities/user.dart';

// CORRECT:
// 1. Naming: Matches `{{name}}Model` (UserModel).
// 2. Grammar: `User` is a Noun Phrase.
// 3. Inheritance: Extends the corresponding Domain Entity (`User`).
class UserModel extends User {
  // Models often have extra fields for serialization that aren't in the Entity
  final String? internalApiId;

  const UserModel({
    required super.id,
    required super.name,
    this.internalApiId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] as String,
    name: json['name'] as String,
    internalApiId: json['meta_id'] as String?,
  );

  // CORRECT:
  // 4. Mapping: Implements `toEntity()` to convert back to the pure Domain object.
  User toEntity() => User(id: id, name: name);
}
