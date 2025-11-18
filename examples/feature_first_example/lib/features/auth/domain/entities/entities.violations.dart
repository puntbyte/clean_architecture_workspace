// example/lib/features/auth/domain/entities/entities.violations.dart

// VIOLATION: disallow_flutter_imports_in_domain
import 'package:example/core/entity/entity.dart';
import 'package:flutter/material.dart';

// VIOLATION: enforce_entity_contract
// The class `User` does not extend the base entity class `Entity`.
class UncontractedUser { // <-- LINT WARNING HERE
  const UncontractedUser();
}

// This entity uses a Flutter type, which is not allowed in the domain layer.
class InvalidUserEntity extends Entity {
  final String id;
  // VIOLATION: disallow_flutter_types_in_domain
  final Color profileColor; // <-- LINT WARNING HERE (type purity)

  const InvalidUserEntity({required this.id, required this.profileColor});
}
