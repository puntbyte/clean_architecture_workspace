// lib/features/auth/presentation/manager/auth_event.dart

part of 'auth_bloc.dart';

// LINT: [Structure] arch_structure_modifier
// REASON: Event Interfaces must be 'sealed' or 'abstract'.
class AuthEvent {} //! <-- WARNING

// LINT: [Naming] arch_naming_pattern (Grammar)
// REASON: Events represent something that *happened*.
// Pattern expected: '{{noun}}{{verb.past}}' (e.g., LoginRequested).
// 'DoLogin' is an imperative command (Anti-pattern for events).
class DoLogin extends AuthEvent { //! <-- WARNING
  final String username;
  DoLogin(this.username);
}

// LINT: [Naming] arch_naming_pattern
// REASON: Missing the parent class suffix or strict naming convention
// (if config requires {{name}}Event for all subclasses).
class Reset extends AuthEvent {} //! <-- WARNING