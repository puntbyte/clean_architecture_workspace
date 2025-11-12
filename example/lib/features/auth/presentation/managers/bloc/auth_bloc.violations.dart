// example/lib/features/auth/presentation/managers/auth_bloc.violations.dart

// VIOLATION: enforce_layer_independence (presentation cannot import from data)
import 'packag:example/features/auth/data/repositories/default_auth_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:example/features/auth/domain/contracts/auth_repository.dart';
import 'package:example/features/auth/domain/usecases/get_user.dart';

// Assume getIt is configured somewhere
dynamic getIt<T>() => throw UnimplementedError();

sealed class AuthEvent {}

sealed class AuthState {}

class AuthInitial extends AuthState {}

class BadDependencyBloc extends Bloc<AuthEvent, AuthState> {
  // VIOLATION: disallow_repository_in_presentation (depends on a repository)
  final AuthRepository _repository; // <-- LINT WARNING HERE

  BadDependencyBloc(this._repository) : super(AuthInitial());
}

class ServiceLocatorBloc extends Bloc<AuthEvent, AuthState> {
  ServiceLocatorBloc() : super(AuthInitial()) {
    on<AuthEvent>((event, emit) {
      // VIOLATION: disallow_service_locator (uses getIt instead of constructor injection)
      final usecase = getIt<GetUser>(); // <-- LINT WARNING HERE
      usecase.call(1);
    });
  }
}
