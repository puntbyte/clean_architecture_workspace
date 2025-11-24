// lib/features/auth/domain/entities/user.violations.dart

import 'package:example/core/entity/entity.dart';

// 1. LINT: disallow_flutter_in_domain
// Reason: The domain layer must be platform-agnostic.
import 'package:flutter/material.dart'; // <-- LINT WARNING HERE

// 2. LINT: enforce_layer_independence
// Reason: Domain layer cannot import from the Data layer.
import 'package:example/features/auth/data/models/user_model.dart'; // <-- LINT WARNING HERE

// 3. LINT: enforce_annotations (Forbidden)
// Reason: Entities should be simple POJOs and not use Dependency Injection annotations.
import 'package:injectable/injectable.dart'; // <-- LINT WARNING HERE

// 4. LINT: enforce_naming_antipattern
// Reason: The class name matches the antipattern `{{name}}Entity`.
// Entities should be named `User`, not `UserEntity`.
@Injectable() // <-- LINT WARNING HERE (3. enforce_annotations)
class UserEntity extends Entity { // <-- LINT WARNING HERE (4. enforce_naming_conventions)
  final String id;

  // 5. LINT: disallow_flutter_in_domain
  // Reason: `Color` is a UI type from dart:ui / flutter.
  final Color profileColor; // <-- LINT WARNING HERE

  const UserEntity({required this.id, required this.profileColor});
}

// 6. LINT: enforce_entity_contract
// Reason: All entities must extend the base `Entity` class defined in Core.
class UncontractedUser { // <-- LINT WARNING HERE
  final String id;
  const UncontractedUser(this.id);
}

// 7. LINT: disallow_model_in_domain
// Reason: Entities cannot hold references to Data Models (DTOs).
class ImpureUser extends Entity {
  final String id;

  // The domain should strictly use other Entities or Value Objects, not Models.
  final UserModel linkedAccount; // <-- LINT WARNING HERE

  const ImpureUser({required this.id, required this.linkedAccount});
}

// 8. LINT: enforce_semantic_naming
// Reason: Grammar violation. Entities must be Noun Phrases (e.g., 'User').
// 'FetchingUser' implies an action (Verb), which is reserved for UseCases.
class FetchingUser extends Entity { // <-- LINT WARNING HERE
  const FetchingUser();
}