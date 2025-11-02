// example/lib/features/auth/domain/entities/user_entity.violations.dart

// VIOLATION: disallow_flutter_imports_in_domain
import 'package:flutter/material.dart';

// VIOLATION: enforce_naming_conventions
// The class name `User` does not match the configured format: `{{name}}Entity`.
class User { // <-- LINT WARNING HERE (naming)
  final String id;
  final String name;

  const User({required this.id, required this.name});
}

// This entity uses a Flutter type, which is not allowed in the domain layer.
class InvalidUserEntity {
  final String id;
  // VIOLATION: disallow_flutter_types_in_domain
  final Color profileColor; // <-- LINT WARNING HERE (type purity)

  const InvalidUserEntity({required this.id, required this.profileColor});
}
