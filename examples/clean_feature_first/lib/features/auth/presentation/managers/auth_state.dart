// lib/features/auth/presentation/manager/auth_state.dart

part of 'auth_bloc.dart';

// LINT: [Structure] arch_structure_modifier
// REASON: State Interfaces must be 'sealed' or 'abstract' to enforce exhaustive matching.
class AuthState {} //! <-- WARNING

// LINT: [Structure] arch_structure_kind
// REASON: Config requires States to be Classes, but this is an Enum.
enum AuthStatus { initial, loading } //! <-- WARNING (If config restricts kind)

class AuthInitial extends AuthState {}