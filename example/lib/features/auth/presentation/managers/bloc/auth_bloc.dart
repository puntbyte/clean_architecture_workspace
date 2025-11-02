import 'package:bloc/bloc.dart';

import '../../../domain/usecases/get_current_user_usecase.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetCurrentUserUsecase _getCurrentUser;

  AuthBloc(this._getCurrentUser) : super(AuthInitial());
}

sealed class AuthEvent {}

sealed class AuthState {}

class AuthInitial extends AuthState {}
