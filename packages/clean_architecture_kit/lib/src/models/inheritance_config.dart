// lib/src/models/inheritance_config.dart

/// A private class to hold the default values for the core package.
class _CoreDefaults {
  /// The path to the main export file of the core package.
  /// This provides an excellent, stable default for all base classes.
  static const corePackagePath = 'package:clean_architecture_core/clean_architecture_core.dart';

  /// The default names of the base classes inside the core package.
  static const repositoryBaseName = 'Repository';
  static const unaryUseCaseName = 'UnaryUseCase';
  static const nullaryUseCaseName = 'NullaryUseCase';
}

class InheritanceConfig {
  final String repositoryBasePath;
  final String repositoryBaseName;
  final String unaryUseCasePath;
  final String unaryUseCaseName;
  final String nullaryUseCasePath;
  final String nullaryUseCaseName;

  const InheritanceConfig({
    required this.repositoryBasePath,
    required this.repositoryBaseName,
    required this.unaryUseCasePath,
    required this.unaryUseCaseName,
    required this.nullaryUseCasePath,
    required this.nullaryUseCaseName,
  });

  factory InheritanceConfig.fromMap(Map<String, dynamic> map) {
    return InheritanceConfig(
      repositoryBasePath: map['repository_base_path'] as String? ?? _CoreDefaults.corePackagePath,
      repositoryBaseName:
          map['repository_base_name'] as String? ?? _CoreDefaults.repositoryBaseName,

      // Both use case types are in the same file in the core package.
      unaryUseCasePath: map['unary_use_case_path'] as String? ?? _CoreDefaults.corePackagePath,
      unaryUseCaseName: map['unary_use_case_name'] as String? ?? _CoreDefaults.unaryUseCaseName,

      nullaryUseCasePath: map['nullary_use_case_path'] as String? ?? _CoreDefaults.corePackagePath,
      nullaryUseCaseName:
          map['nullary_use_case_name'] as String? ?? _CoreDefaults.nullaryUseCaseName,
    );
  }
}
