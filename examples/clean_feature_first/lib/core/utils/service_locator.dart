import 'package:get_it/get_it.dart';

// 1. Re-export GetIt so types match
export 'package:get_it/get_it.dart';

// 2. Define the global accessors tracked by your config
final getIt = GetIt.instance;
final locator = GetIt.instance;
final serviceLocator = GetIt.instance;

/// A manual setup function (No build_runner needed)
void configureDependencies() {
  // Manual registration for demonstration
  // locator.registerLazySingleton<AuthRepository>(() => DefaultAuthRepository());
}