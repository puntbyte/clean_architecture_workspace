// example/lib/features/auth/presentation/widgets/login_button.violations.dart
import 'package:flutter/material.dart';
import 'package:example/features/auth/domain/usecases/get_user_usecase.dart';

/// This widget demonstrates a common architectural violation where a developer
/// injects a UseCase directly into a widget to take a shortcut.
class UserProfileViolations extends StatelessWidget {
  /// The widget depends directly on a concrete UseCase implementation.
  final GetUserUsecase getUserUsecase;

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