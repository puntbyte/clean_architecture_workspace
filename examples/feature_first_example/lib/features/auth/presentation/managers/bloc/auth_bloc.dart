import 'package:bloc/bloc.dart';

import '../../../domain/usecases/get_current_user_usecase.dart';

import 'package:bloc/bloc.dart';
import 'package:feature_first_example/features/auth/domain/usecases/login_user.dart';

class AuthBloc extends Cubit<void> {
  final LoginUser _loginUser;

  // CORRECT: Depends on UseCase.
  AuthBloc(this._loginUser) : super(null);

  Future<void> login() async {
    await _loginUser(user: 'a', pass: 'b');
  }
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUserUsecase _getCurrentUser;

  AuthBloc(this._getCurrentUser) : super(AuthInitial());
}

sealed class AuthEvent {}

sealed class AuthState {}

class AuthInitial extends AuthState {}
