// lib/main.dart

import 'package:feature_first_example/features/auth/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Clean Architecture Example',
      home: HomePage(),
    );
  }
}
