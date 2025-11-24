// example/lib/features/auth/domain/ports/auth_port.violations.dart

// 1. LINT: enforce_layer_independence
// Reason: Domain layer cannot import from the Data layer.
import 'package:example/features/auth/data/models/user_model.dart'; // <-- LINT WARNING HERE

// 2. LINT: disallow_flutter_in_domain
// Reason: Domain must be platform agnostic (no UI types).
import 'package:flutter/material.dart'; // <-- LINT WARNING HERE

import 'package:example/core/port/port.dart';
import 'package:example/core/utils/types.dart';
import 'package:example/features/auth/domain/entities/user.dart';

// 3. LINT: enforce_naming_conventions
// Reason: Name must end with 'Port' (configured pattern: `{{name}}Port`).
// We use 'AuthContract' here. If we used 'AuthRepository', the linter would
// flag it as a Location Error (misplaced data repository) instead of a Naming Error.
abstract interface class AuthContract implements Port { // <-- LINT WARNING HERE

  // 4. LINT: enforce_type_safety
  // Reason: Return type must be `FutureEither`, not raw `Future`.
  Future<User> login(String username); // <-- LINT WARNING HERE

  // 5. LINT: disallow_model_in_domain
  // Reason: Cannot return a Data Model from a Domain Port.
  FutureEither<UserModel> unsafeReturn(); // <-- LINT WARNING HERE

  // 6. LINT: disallow_model_in_domain
  // Reason: Cannot accept a Data Model as a parameter.
  FutureEither<void> unsafeParam(UserModel user); // <-- LINT WARNING HERE

  // 7. LINT: missing_use_case
  // Reason: No corresponding UseCase file exists for this method.
  // (Expected: lib/features/auth/domain/usecases/logout.dart)
  FutureEither<void> logout(); // <-- LINT WARNING HERE (Quick Fix available)
}

// 8. LINT: enforce_port_contract
// Reason: Ports must implement/extend the base `Port` interface.
abstract interface class UncontractedAuthPort { // <-- LINT WARNING HERE
  void doSomething();
}

abstract interface class TypeSafetyViolationsPort implements Port {
  // 9. LINT: enforce_type_safety
  // Reason: Parameter named 'id' must be of type `IntId`, not `int`.
  FutureEither<User> getUser(int id); // <-- LINT WARNING HERE

  // 10. LINT: enforce_type_safety
  // Reason: Parameter named 'id' must be of type `StringId`, not `String`.
  FutureEither<void> deleteUser(String id); // <-- LINT WARNING HERE
}

// ignore: enforce_semantic_naming
abstract interface class PurityViolationsPort implements Port {
  // 11. LINT: disallow_flutter_in_domain
  // Reason: Cannot use Flutter types (Color) in Domain.
  Color getUserColor(); // <-- LINT WARNING HERE
}