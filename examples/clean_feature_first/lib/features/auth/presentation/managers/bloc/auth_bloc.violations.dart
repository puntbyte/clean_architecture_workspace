// example/lib/features/auth/presentation/bloc/auth_bloc.violations.dart
import 'package:bloc/bloc.dart';

import 'package:bloc/bloc.dart';
// LINT: disallow_repository_in_presentation
// Reason: Presentation cannot touch Repositories directly.
import 'package:clean_feature_first/features/auth/domain/ports/auth_port.dart';
import 'package:clean_feature_first/features/auth/presentation/managers/bloc/auth_bloc.dart';
// LINT: disallow_service_locator
import 'package:get_it/get_it.dart';

class LazyBloc extends Cubit<void> {
  final AuthPort _repo; // <-- Violation

  LazyBloc(this._repo) : super(null);

  void magic() {
    // LINT: disallow_service_locator
    // Reason: Service Locator pattern is forbidden.
    final loc = GetIt.I.get<AuthPort>();
  }
}

// VIOLATION: disallow_repository_in_presentation
// This BLoC incorrectly depends on the entire AuthRepository.
class AuthBlocViolations extends Bloc<AuthEvent, AuthState> {
  // It should depend on a specific UseCase instead.
  final AuthPort _repository;

  AuthBlocViolations(
    this._repository, // <-- LINT WARNING HERE
  ) : super(AuthInitial());
}
