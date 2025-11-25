// lib/features/auth/domain/entities/user.violations.dart

import 'package:example/core/entity/entity.dart';

// LINT: [1] disallow_flutter_in_domain
// REASON: The domain layer must remain platform-agnostic (no Flutter dependencies).
import 'package:flutter/material.dart'; // <-- LINT WARNING HERE

// LINT: [2] enforce_layer_independence
// REASON: Domain layer must not import components from the Data layer.
import 'package:example/features/auth/data/models/user_model.dart'; // <-- LINT WARNING HERE

// LINT: [3] enforce_annotations (Forbidden Import)
// REASON: Entities should be POJOs; Dependency Injection imports are forbidden.
import 'package:injectable/injectable.dart'; // <-- LINT WARNING HERE (works for here)

@Injectable() // <-- LINT WARNING HERE (not working)
// LINT: [4] enforce_naming_antipattern
// REASON: Name matches antipattern `{{name}}Entity`; use `User` instead.
class UserEntity extends Entity { // <-- LINT WARNING HERE
  final String id;

  // LINT: [5] disallow_flutter_in_domain
  // REASON: `Color` is a UI implementation detail not allowed in Domain.
  final Color profileColor; // <-- LINT WARNING HERE

  // LINT: [6] disallow_model_in_domain
  // REASON: Entities must not reference Data Models; use domain objects only.
  final UserModel linkedAccount; // <-- LINT WARNING HERE

  const UserEntity({required this.id, required this.profileColor, required this.linkedAccount});
}

@injectable // <-- LINT WARNING HERE (not working)
// LINT: [7] enforce_entity_contract
// REASON: Entities must extend the base `Entity` class defined in Core.
class UncontractedUser { // <-- LINT WARNING HERE
  final String id;

  const UncontractedUser(this.id);
}

// LINT: [8] enforce_semantic_naming
// REASON: Grammar violation: Entities must be Noun phrases, not actions (Verbs).
class FetchingUser extends Entity {
  // <-- LINT WARNING HERE
  const FetchingUser();
}
