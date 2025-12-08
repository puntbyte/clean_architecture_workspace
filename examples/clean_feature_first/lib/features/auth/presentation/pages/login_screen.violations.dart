import 'package:clean_feature_first/features/auth/domain/usecases/usecase.violations.dart';
import 'package:flutter/material.dart';
// LINT: [Dep] arch_dep_layer
// REASON: Presentation layer cannot import Data layer. Use Domain UseCases/Entities.
import 'package:clean_feature_first/features/auth/data/repositories/auth_repository_impl.dart'; //! <-- WARNING

// LINT: [Naming] arch_naming_antipattern
// REASON: Pages should end with 'Page', not 'Screen'.
// LINT: [Inheritance] arch_type_forbidden
// REASON: Pages must not extend StatefulWidget. Use Stateless/HookWidget + Bloc.
// ignore: arch_naming_pattern, arch_naming_antipattern, arch_type_missing_base
class LoginScreen extends StatefulWidget { //! <-- WARNING (Naming & Inheritance)
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // LINT: [Usage] arch_usage_instantiation
  // REASON: Direct instantiation of Data component in UI.
  final repo = AuthRepositoryImpl(); //! <-- WARNING

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Container());
  }
}