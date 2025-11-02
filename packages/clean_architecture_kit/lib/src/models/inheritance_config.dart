// lib/src/models/inheritance_config.dart

import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';

/// A private class to hold the default values for the core package.
class _CoreDefaults {
  static const corePackagePath = 'package:clean_architecture_core/clean_architecture_core.dart';
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
      repositoryBasePath: map.getString(
        'repository_base_path',
        orElse: _CoreDefaults.corePackagePath,
      ),
      repositoryBaseName: map.getString(
        'repository_base_name',
        orElse: _CoreDefaults.repositoryBaseName,
      ),

      unaryUseCasePath: map.getString('unary_use_case_path', orElse: _CoreDefaults.corePackagePath),
      unaryUseCaseName: map.getString(
        'unary_use_case_name',
        orElse: _CoreDefaults.unaryUseCaseName,
      ),

      nullaryUseCasePath: map.getString(
        'nullary_use_case_path',
        orElse: _CoreDefaults.corePackagePath,
      ),
      nullaryUseCaseName: map.getString(
        'nullary_use_case_name',
        orElse: _CoreDefaults.nullaryUseCaseName,
      ),
    );
  }
}
