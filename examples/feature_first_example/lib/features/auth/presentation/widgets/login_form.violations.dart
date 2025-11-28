// lib/features/auth/presentation/widgets/login_form.violations.dart

import 'package:flutter/material.dart';
import 'package:feature_first_example/features/auth/domain/usecases/get_user.dart';

import 'package:flutter/material.dart';
// LINT: disallow_use_case_in_widget
// Reason: Widgets shouldn't call UseCases. Logic belongs in Managers.
import 'package:feature_first_example/features/auth/domain/usecases/login_user.dart';

class LoginForm extends StatelessWidget {
  final LoginUser loginUser; // <-- Violation

  const LoginForm({super.key, required this.loginUser});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // LINT: disallow_use_case_in_widget
        loginUser(user: 'a', pass: 'b');
      },
      child: const Text('Login'),
    );
  }
}

/// This widget demonstrates a common architectural violation where a developer
/// injects a UseCase directly into a widget to take a shortcut.
class UserProfileViolations extends StatelessWidget {
  /// The widget depends directly on a concrete UseCase implementation.
  final GetUser getUserUsecase;

  const UserProfileViolations({
    super.key,
    required this.getUserUsecase,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // VIOLATION: disallow_use_case_in_widget
        // The widget is invoking business logic directly from a user interaction.
        getUserUsecase.call(123); // <-- LINT WARNING HERE
      },
      child: const Text('Fetch User Profile'),
    );
  }
}