import 'package:flutter/material.dart';
// LINT: [Dep] arch_dep_layer
// REASON: Widgets should not depend on Pages (Circular dependency risk).
// Widgets are reusable leaves; Pages are containers.
import 'package:clean_feature_first/features/auth/presentation/pages/home_page.dart'; //! <-- WARNING

// ignore: arch_naming_pattern
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  void _navigateToHome(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomePage())
    );
  }

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar();
  }
}