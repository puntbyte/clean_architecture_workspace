// lib/features/auth/domain/ports/auth_port.violations.dart

import 'package:clean_feature_first/core/port/port.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:clean_feature_first/features/auth/domain/entities/user.dart';

// LINT: [1] arch_dep_component
// REASON: Domain layer cannot import from the Data layer.
import 'package:clean_feature_first/features/auth/data/models/user_model.dart'; //! <-- LINT WARNING

// LINT: [2] arch_dep_external
// REASON: Domain must be platform agnostic (no UI types).
import 'package:flutter/material.dart'; //! <-- LINT WARNING

// LINT: [3] arch_naming_pattern
// REASON: Name must match the pattern `{{name}}Port` (e.g., AuthPort).
abstract interface class AuthContract implements Port {
  // LINT: [4] arch_safety_return_forbidden
  // REASON: Return type must be `FutureEither<T>`, not raw `Future<T>`.
  Future<User> login(String username); //! <-- LINT WARNING

  // LINT: [4] arch_dep_component
  // REASON: Cannot return a Data Model (DTO) from a Domain Port. Use Entities.
  FutureEither<UserModel> unsafeReturn(); //! <-- LINT WARNING

  // LINT: [9] arch_safety_param_forbidden
  // REASON: Parameter named 'id' must be of type `IntId`, not `int`.
  FutureEither<User> unsafeParameter(int id); //! <-- LINT WARNING

  FutureEither<User> getUser(IntId id);
}

// LINT: [8] arch_type_missing_base
// REASON: Ports must implement/extend the base `Port` interface defined in Core.
abstract interface class UncontractedAuthPort { //! <-- LINT WARNING
  // LINT: [8] arch_safety_return_strict
  // REASON: Return type must be `FutureEither<T>`, not `void`.
  void doSomething(); //! <-- LINT WARNING

  // LINT: [6] arch_dep_component
  // REASON: Cannot accept a Data Model as a parameter. Use Entities.
  FutureEither<void> unsafeParam(UserModel user); //! <-- LINT WARNING

  // LINT: [7*] missing_use_case
  // REASON: No corresponding UseCase file found for method `revokeToken`.
  // (Expected: lib/features/auth/domain/usecases/revoke_token.dart)
  FutureEither<void> revokeToken(); //! <-- LINT WARNING (Quick Fix available)
}

abstract interface class TypeSafetyViolationsPort implements Port {
  // LINT: arch_safety_return_forbidden
  // REASON: Return type must be `FutureEither<T>`, not raw `Future<T>`.
  Future<User> login(String username); //! <-- LINT WARNING

  // LINT: [9] enforce_type_safety
  // REASON: Parameter named 'id' must be of type `IntId`, not `int`.
  FutureEither<User> unsafeIntIdParameter(int id); //! <-- LINT WARNING

  // LINT: [10] enforce_type_safety
  // REASON: Parameter named 'id' must be of type `StringId`, not `String`.
  FutureEither<void> unsafeIntStringParameter(String id); //! <-- LINT WARNING
}

abstract interface class PurityViolationsPort implements Port {
  // LINT: [11] disallow_flutter_in_domain
  // REASON: Cannot use Flutter types (Color) in the Domain layer.
  // ignore: missing_use_case, arch_safety_return_strict
  Color getUserColor(); //! <-- LINT WARNING
}

// LINT: [12] arch_naming_grammar
// REASON: Grammar violation. Ports should be Noun Phrases (e.g., AuthPort).
// 'FetchingUserPort' implies an action (Verb), which is reserved for UseCases.
abstract interface class FetchingUserPort implements Port { //! <-- LINT WARNING
  FutureEither<User> fetch();
}
