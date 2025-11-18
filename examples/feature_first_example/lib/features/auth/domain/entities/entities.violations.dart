// example/lib/features/auth/domain/entities/entities.violations.dart

import 'package:example/core/entity/entity.dart';
// VIOLATION: disallow_flutter_imports_in_domain
// The import `package:flutter/material.dart` is not allowed in the domain layer.
import 'package:flutter/material.dart'; // <-- LINT WARNING HERE

// VIOLATION: enforce_entity_contract
// The class `User` does not extend the base entity class `Entity`.
class UncontractedUser { // <-- LINT WARNING HERE
  const UncontractedUser();
}

// VIOLATION: enforce_naming_convention
// The class `UserEntity` has a suffix `Entity` which is forbidden for entities.
class UserEntity implements Entity { // <-- LINT WARNING HERE
  final String id;
  // VIOLATION: disallow_flutter_types_in_domain
  // Flutter type `Color` is not allowed in the domain layer.
  final Color profileColor; // <-- LINT WARNING HERE

  const UserEntity({required this.id, required this.profileColor});
}
