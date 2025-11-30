// lib/features/auth/domain/entities/entity.violations.dart

import 'package:feature_first_example/core/entity/entity.dart';

// LINT: [1] disallow_flutter_in_domain
// REASON: The domain layer must remain platform-agnostic (no Flutter dependencies).
import 'package:flutter/material.dart'; //! <-- LINT WARNING (Forbidden Import)

// LINT: [2] enforce_layer_independence
// REASON: Domain layer must not import components from the Data layer.
import 'package:feature_first_example/features/auth/data/models/user_model.dart'; //! <-- LINT WARNING

// LINT: [3] enforce_annotations (Forbidden Import)
// REASON: Entities should be POJOs; Dependency Injection imports are forbidden.
import 'package:injectable/injectable.dart'; //! <-- LINT WARNING (the warning is visible)

// LINT: [4] enforce_annotations (Forbidden Annotation)
// REASON: Entities should be POJOs; Dependency Injection annotations are forbidden.
@Injectable() @lazySingleton //! <-- LINT WARNING
class AnnotatedUser extends Entity {}

// LINT: [5] enforce_naming_antipattern
// REASON: Name matches antipattern `{{name}}Entity`; use `User` instead.
class UserEntity extends Entity { //! <-- LINT WARNING
  final String id;

  // LINT: [6] disallow_flutter_in_domain (Forbidden Class)
  // REASON: `Color` is a UI implementation detail not allowed in Domain.
  final Color profileColor; //! <-- LINT WARNING

  // LINT: [7 disallow_model_in_domain
  // REASON: Entities must not reference Data Models; use domain objects only.
  final UserModel linkedAccount; //! <-- LINT WARNING

  const UserEntity({required this.id, required this.profileColor, required this.linkedAccount});
}

// LINT: [8] enforce_entity_contract
// REASON: Entities must extend the base `Entity` class defined in Core.
class UncontractedUser { //! <-- LINT WARNING
  final String id;

  const UncontractedUser(this.id);
}

// LINT: [9] enforce_semantic_naming
// REASON: Grammar violation: Entities must be Noun phrases, not actions (Verbs).
class FetchingUser extends Entity { //! <-- LINT WARNING
  const FetchingUser();
}
