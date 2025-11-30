// lib/features/auth/domain/ports/auth_port.violations.dart

import 'package:feature_first_example/core/port/port.dart';
import 'package:feature_first_example/core/utils/types.dart';
import 'package:feature_first_example/features/auth/domain/entities/user.dart';

// LINT: [1] enforce_layer_independence
// REASON: Domain layer cannot import from the Data layer.
import 'package:feature_first_example/features/auth/data/models/user_model.dart'; //! <-- LINT WARNING

// LINT: [2] disallow_flutter_in_domain
// REASON: Domain must be platform agnostic (no UI types).
import 'package:flutter/material.dart'; //! <-- LINT WARNING

// LINT: [3] enforce_naming_pattern
// REASON: Name must match the pattern `{{name}}Port` (e.g., AuthPort).
abstract interface class AuthContract implements Port { //! <-- LINT WARNING

  // LINT: [4] enforce_type_safety
  // REASON: Return type must be `FutureEither<T>`, not raw `Future<T>`.
  Future<User> login(String username); //! <-- LINT WARNING

  // LINT: [5] disallow_model_in_domain
  // REASON: Cannot return a Data Model (DTO) from a Domain Port. Use Entities.
  // ignore: missing_use_case
  FutureEither<UserModel> unsafeReturn(); //! <-- LINT WARNING

  // LINT: [6] disallow_model_in_domain
  // REASON: Cannot accept a Data Model as a parameter. Use Entities.
  // ignore: missing_use_case
  FutureEither<void> unsafeParam(UserModel user); //! <-- LINT WARNING

  // LINT: [7] missing_use_case
  // REASON: No corresponding UseCase file found for method `revokeToken`.
  // (Expected: lib/features/auth/domain/usecases/revoke_token.dart)
  FutureEither<void> revokeToken(); //! <-- LINT WARNING (Quick Fix available)
}

// LINT: [8] enforce_port_contract
// REASON: Ports must implement/extend the base `Port` interface defined in Core.
abstract interface class UncontractedAuthPort { //! <-- LINT WARNING
  // ignore: missing_use_case
  void doSomething();
}

abstract interface class TypeSafetyViolationsPort implements Port {
  // LINT: [8] enforce_type_safety
  // REASON: Return type must be `FutureEither<T>`, not raw `Future<T>`.
  Future<User> login(String username); //! <-- LINT WARNING

  // LINT: [9] enforce_type_safety
  // REASON: Parameter named 'id' must be of type `IntId`, not `int`.
  // ignore: missing_use_case
  FutureEither<User> getUser(int id); //! <-- LINT WARNING

  // LINT: [10] enforce_type_safety
  // REASON: Parameter named 'id' must be of type `StringId`, not `String`.
  // ignore: missing_use_case
  FutureEither<void> deleteUser(String id); //! <-- LINT WARNING
}

abstract interface class PurityViolationsPort implements Port {
  // LINT: [11] disallow_flutter_in_domain
  // REASON: Cannot use Flutter types (Color) in the Domain layer.
  // ignore: missing_use_case
  Color getUserColor(); //! <-- LINT WARNING
}

// LINT: [12] enforce_semantic_naming
// REASON: Grammar violation. Ports should be Noun Phrases (e.g., AuthPort).
// 'FetchingUserPort' implies an action (Verb), which is reserved for UseCases.
abstract interface class FetchingUserPort implements Port { //! <-- LINT WARNING
  // ignore: missing_use_case
  FutureEither<User> fetch();
}
