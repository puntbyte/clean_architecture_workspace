// lib/features/auth/domain/usecases/usecase.violations.dart

import 'package:clean_feature_first/core/usecase/usecase.dart';
import 'package:clean_feature_first/core/utils/service_locator.dart';
import 'package:clean_feature_first/core/utils/types.dart';
import 'package:injectable/injectable.dart';

// Lint: [1] arch_dep_component
// Reason: Domain layer cannot import from the Data layer.
import 'package:clean_feature_first/features/auth/data/models/user_model.dart'; //! <-- LINT WARNING

// Lint: [2] arch_dep_component
// Reason: Domain must depend on Interfaces (Ports), not Concrete Implementations.
import 'package:clean_feature_first/features/auth/data/repositories/auth_repository.dart'; //! <-- LINT WARNING

// Lint: [3]: arch_dep_component
// Reason: Domain layer cannot import from the Data layer.
import 'package:clean_feature_first/features/auth/data/sources/default_auth_source.dart'; //! <-- LINT WARNING
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';

// Lint: [4*] disallow_service_locator
// Reason: Service Locators hide dependencies; use Constructor Injection.
import 'package:get_it/get_it.dart'; //! <-- LINT WARNING

// LINT: [5] arch_dep_external
// Reason: Domain layer must be platform-agnostic (no UI types).
import 'package:flutter/material.dart'; //! <-- LINT WARNING

// LINT: [5*] arch_naming_grammar
// Reason: Grammar violation. UseCases must be `VerbNoun` (e.g., `LoginUser`), not `NounVerb`
// (`UserLogin`).
@injectable
// ignore: arch_type_missing_base
class UserLogin { //! <-- LINT WARNING
  const UserLogin();
}

// LINT: [6] arch_naming_antipattern
// Reason: Name uses forbidden suffix `UseCase`. Pattern should be `{{name}}` (e.g. `GetProfile`).
@injectable
// ignore: arch_type_missing_base
class GetProfileUseCase { //! <-- LINT WARNING
  const GetProfileUseCase();
}

// LINT: [7] arch_annot_missing (Required)
// Reason: UseCases must be annotated with `@Injectable`.
// ignore: arch_type_missing_base, arch_naming_grammar
class LogoutUser { //! <-- LINT WARNING
}

// LINT: [8] arch_type_missing_base
// Reason: UseCases must implement/extend `UnaryUsecase` or `NullaryUsecase`.
@injectable
class LoginUser { //! <-- LINT WARNING
  // LINT: [13] arch_safety_return_forbidden
  // Reason: Return type must be `FutureEither`, not raw `Future`.
  Future<void> call() async => throw UnimplementedError(); //! <-- LINT WARNING
}

@Injectable()
class GetUser implements UnaryUsecase<dynamic, int> {
  // LINT: [9] arch_dep_component
  // Reason: Dependency is a concrete class `DefaultAuthRepository`. Use the interface.
  final DefaultAuthRepository repo;

  const GetUser(this.repo);

  FutureEither<void> antiPatterns() {
    // LINT: [10] arch_usage_instantiation
    // Reason: Dependencies must be injected, not created inside the class.
    final localRepo = DefaultAuthRepository( //! <-- LINT WARNING
      // Lint: [10] arch_dep_component
      // Reason: Dependency is a concrete class `DefaultAuthRepository`. Use the interface.
      DefaultAuthSource(), //! <-- LINT WARNING
    );

    // LINT: [11a] arch_usage_global_access
    // Reason: Accessing 'GetIt' type directly via static property.
    final loc1 = GetIt.I.get<AuthPort>(); //! <-- LINT WARNING

    // LINT: [11b] arch_usage_global_access
    // Reason: Accessing 'locator' global variable from your wrapper.
    final loc2 = locator<DefaultAuthRepository>(); //! <-- LINT WARNING

    // LINT: [11c] arch_usage_global_access
    // Reason: Accessing 'getIt' global variable.
    final loc3 = getIt<AuthPort>(); //! <-- LINT WARNING

    throw UnimplementedError();
  }

  @override
  FutureEither<dynamic> call(int parameter) => throw UnimplementedError();
}

// ignore: arch_annot_missing
class BadTypes implements NullaryUsecase<void> {

  // LINT: [12] arch_safety_param_forbidden
  // Reason: Parameter named `id` must be `IntId`, not primitive `int`.
  FutureEither<dynamic> unsafeParameterCall(int id) async { //! <-- LINT WARNING
    throw UnimplementedError();
  }

  // LINT: [14] arch_dep_component
  // Reason: UseCases cannot return Data Models. Use Entities.
  FutureEither<UserModel> unsafeReturnCall() async { //! <-- LINT WARNING
    throw UnimplementedError();
  }

  @override
  FutureEither<void> call() => throw UnimplementedError();
}

// LINT: [15] arch_dep_external
// Reason: Domain layer must be platform-agnostic (no UI types).
// ignore: arch_annot_missing
class FetchColor implements NullaryUsecase<Color> { //! <-- LINT WARNING
  @override
  FutureEither<Color> call() { //! <-- LINT WARNING
    return Future.value.call();
  }
}

// LINT: [16*] enforce_file_and_folder_location
// Reason: This is a Repository Implementation (Data Layer), incorrectly placed in the UseCases
// folder.
// ignore: arch_naming_grammar, arch_type_missing_base
class AuthRepositoryImpl { //! <-- LINT WARNING
  const AuthRepositoryImpl();
}