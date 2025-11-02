// example/lib/features/auth/presentation/bloc/auth_bloc.violations.dart
import 'package:bloc/bloc.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:example/features/auth/presentation/managers/bloc/auth_bloc.dart';

// VIOLATION: disallow_repository_in_presentation
// This BLoC incorrectly depends on the entire AuthRepository.
class AuthBlocViolations extends Bloc<AuthEvent, AuthState> {
  // It should depend on a specific UseCase instead.
  final AuthRepository _repository;

  AuthBlocViolations(
    this._repository, // <-- LINT WARNING HERE
  ) : super(AuthInitial());
}
