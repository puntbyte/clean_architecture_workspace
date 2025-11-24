// example/lib/features/auth/presentation/bloc/auth_bloc.violations.dart
import 'package:bloc/bloc.dart';
import 'package:example/features/auth/domain/contracts/auth_port.dart';
import 'package:example/features/auth/presentation/managers/bloc/auth_bloc.dart';

import 'package:bloc/bloc.dart';
// LINT: disallow_repository_in_presentation
// Reason: Presentation cannot touch Repositories directly.
import 'package:example/features/auth/domain/contracts/auth_port.dart';
// LINT: disallow_service_locator
import 'package:get_it/get_it.dart';

class LazyBloc extends Cubit<void> {
  final AuthRepository _repo; // <-- Violation

  LazyBloc(this._repo) : super(null);

  void magic() {
    // LINT: disallow_service_locator
    // Reason: Service Locator pattern is forbidden.
    final loc = GetIt.I.get<AuthRepository>();
  }
}

// VIOLATION: disallow_repository_in_presentation
// This BLoC incorrectly depends on the entire AuthRepository.
class AuthBlocViolations extends Bloc<AuthEvent, AuthState> {
  // It should depend on a specific UseCase instead.
  final AuthRepository _repository;

  AuthBlocViolations(
    this._repository, // <-- LINT WARNING HERE
  ) : super(AuthInitial());
}
