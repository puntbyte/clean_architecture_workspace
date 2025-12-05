// lib/features/auth/domain/entities/entity.violations.dart

import 'package:clean_feature_first/core/entity/entity.dart';

// LINT: [1] arch_dep_external
// REASON: The domain layer must remain platform-agnostic (no Flutter dependencies).
import 'package:flutter/material.dart'; //! <-- LINT WARNING (Forbidden Import)

// LINT: [2] arch_dep_component
// REASON: Domain layer must not import components from the Data layer.
import 'package:clean_feature_first/features/auth/data/models/user_model.dart'; //! <-- LINT WARNING

// LINT: [3] enforce_annotations (Forbidden Import)
// REASON: Entities should be POJOs; Dependency Injection imports are forbidden.
import 'package:injectable/injectable.dart'; //! <-- LINT WARNING (the warning is visible)

// LINT: [4*] enforce_annotations (Forbidden Annotation)
// REASON: Entities should be POJOs; Dependency Injection annotations are forbidden.
@Injectable() @lazySingleton //! <-- LINT WARNING
// ignore: arch_member_missing
class AnnotatedUser extends Entity {}

// LINT: [5] arch_naming_antipattern
// REASON: Name matches antipattern `{{name}}Entity`; use `User` instead.
class UserEntity extends Entity { //! <-- LINT WARNING
  final String id;

  // LINT: [6] arch_dep_external
  // REASON: `Color` is a UI implementation detail not allowed in Domain.
  final Color profileColor; //! <-- LINT WARNING

  // LINT: [7] arch_dep_component
  // REASON: Entities must not reference Data Models; use domain objects only.
  final UserModel linkedAccount; //! <-- LINT WARNING

  const UserEntity({required this.id, required this.profileColor, required this.linkedAccount});
}

// LINT: [8] arch_type_missing_base
// REASON: Entities must extend the base `Entity` class defined in Core.
class UncontractedUser { //! <-- LINT WARNING
  final String id;

  const UncontractedUser(this.id);
}

// LINT: [9] arch_naming_grammar
// REASON: Grammar violation: Entities must be Noun phrases, not actions (Verbs).
// ignore: arch_member_missing
class FetchingUser extends Entity { //! <-- LINT WARNING
  const FetchingUser();
}
