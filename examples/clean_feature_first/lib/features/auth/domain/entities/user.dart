// lib/features/auth/domain/entities/user.dart

import 'package:clean_feature_first/core/entity/entity.dart';

// CORRECT: Extends Entity, follows naming (No 'Entity' suffix).
class User extends Entity {
  final String id;
  final String name;

  const User({required this.id, required this.name});
}
