import 'package:bloc/bloc.dart';
import 'package:clean_feature_first/features/auth/domain/usecases/request_login.dart';


import 'package:bloc/bloc.dart';

class AuthBloc extends Cubit<void> {
  final Login _loginUser;

  // CORRECT: Depends on UseCase.
  AuthBloc(this._loginUser) : super(null);

  Future<void> login() async {
    await _loginUser((username: 'a', password: 'b'));
  }
}


sealed class AuthEvent {}

sealed class AuthState {}

class AuthInitial extends AuthState {}
