// example/lib/features/auth/domain/usecases/usecases.violations.dart

import 'package:example/core/usecase/usecase.dart';
import 'package:example/core/utils/types.dart';

// LINT: [1] disallow_flutter_in_domain
// REASON: Domain layer must be platform-agnostic (no UI types).
import 'package:flutter/material.dart'; // <-- LINT WARNING HERE

// LINT: [2] enforce_layer_independence
// REASON: Domain layer cannot import from the Data layer.
import 'package:example/features/auth/data/models/user_model.dart'; // <-- LINT WARNING HERE

// LINT: [3] enforce_abstract_repository_dependency
// REASON: Domain must depend on Interfaces (Ports), not Concrete Implementations.
import 'package:example/features/auth/data/repositories/auth_repository_imp.dart'; // <-- LINT WARNING HERE

// LINT: [4] disallow_service_locator
// REASON: Service Locators hide dependencies; use Constructor Injection.
import 'package:get_it/get_it.dart'; // <-- LINT WARNING HERE

// LINT: [5] enforce_semantic_naming
// REASON: Grammar violation. UseCases must be `VerbNoun` (e.g., `LoginUser`), not `NounVerb` (`UserLogin`).
class UserLogin { // <-- LINT WARNING HERE
  // ...
}

// LINT: [6] enforce_naming_antipattern
// REASON: Name uses forbidden suffix `UseCase`. Pattern should be `{{name}}` (e.g. `GetProfile`).
class GetProfileUseCase { // <-- LINT WARNING HERE
  // ...
}

// LINT: [7] enforce_annotations (Required)
// REASON: UseCases must be annotated with `@Injectable`.
// LINT: [8] enforce_usecase_contract
// REASON: UseCases must implement/extend `UnaryUsecase` or `NullaryUsecase`.
class LogoutUser { // <-- LINT WARNING HERE (Missing Annotation & Contract)
  void call() {}
}

// Correct Naming and Inheritance, but internal violations
// ignore: enforce_annotations
class GetUser implements UnaryUsecase<dynamic, int> {
  // LINT: [9] enforce_abstract_repository_dependency
  // REASON: Dependency is a concrete class `DefaultAuthRepository`. Use the interface.
  final DefaultAuthRepository repo; // <-- LINT WARNING HERE

  GetUser(this.repo);

  void antiPatterns() {
    // LINT: [10] disallow_dependency_instantiation
    // REASON: Dependencies must be injected, not created inside the class.
    final localRepo = DefaultAuthRepository(); // <-- LINT WARNING HERE

    // LINT: [11] disallow_service_locator
    // REASON: Do not use `getIt` inside business logic.
    final loc = GetIt.I.get<DefaultAuthRepository>(); // <-- LINT WARNING HERE
  }

  // LINT: [12] enforce_type_safety
  // REASON: Parameter named `id` must be `IntId`, not primitive `int`.
  @override
  FutureEither<dynamic> call(int id) async { // <-- LINT WARNING HERE
    throw UnimplementedError();
  }
}

// ignore: enforce_annotations
class BadTypes implements NullaryUsecase<void> {
  // LINT: [13] enforce_type_safety
  // REASON: Return type must be `FutureEither`, not raw `Future`.
  @override
  Future<void> call() async {} // <-- LINT WARNING HERE

  // LINT: [14] disallow_model_in_domain
  // REASON: UseCases cannot return Data Models. Use Entities.
  FutureEither<UserModel> unsafeCall() async { // <-- LINT WARNING HERE
    throw UnimplementedError();
  }
}

// LINT: [15] enforce_file_and_folder_location
// REASON: This is a Repository Implementation (Data Layer), incorrectly placed in the UseCases folder.
class AuthRepositoryImpl { // <-- LINT WARNING HERE
  const AuthRepositoryImpl();
}