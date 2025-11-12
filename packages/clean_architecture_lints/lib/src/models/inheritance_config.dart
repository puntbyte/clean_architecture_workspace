// lib/src/models/inheritance_config.dart

import 'package:clean_architecture_kit/src/models/rules/inheritance_rule.dart';
import 'package:clean_architecture_kit/src/utils/extensions/json_map_extension.dart';


/// The parent configuration class for all inheritance rules.
class InheritanceConfig {
  final List<InheritanceRule> rules;

  const InheritanceConfig({required this.rules});

  factory InheritanceConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = (map['inheritances'] as List<dynamic>?) ?? [];

    return InheritanceConfig(
      rules: ruleList
          .whereType<Map<String, dynamic>>()
          .map(InheritanceRule.fromMap)
          .toList(),
    );
  }
}


/// A strongly-typed representation of the `inheritance` block in `analysis_options.yaml`.
/*class InheritanceConfig {
  final String entityBaseName;
  final String entityBasePath;

  final String unaryUseCaseName;
  final String unaryUseCasePath;

  final String nullaryUseCaseName;
  final String nullaryUseCasePath;

  final String repositoryBaseName;
  final String repositoryBasePath;

  const InheritanceConfig({
    required this.entityBaseName,
    required this.entityBasePath,

    required this.unaryUseCaseName,
    required this.unaryUseCasePath,

    required this.nullaryUseCaseName,
    required this.nullaryUseCasePath,

    required this.repositoryBasePath,
    required this.repositoryBaseName,
  });

  factory InheritanceConfig.fromMap(Map<String, dynamic> map) {
    return InheritanceConfig(
      entityBaseName: map.getString('entity_base_name', _CoreDefaults.entityBaseName),
      entityBasePath: map.getString('entity_base_path', _CoreDefaults.corePackagePath),

      unaryUseCaseName: map.getString('unary_use_case_name', _CoreDefaults.unaryUseCaseName),
      unaryUseCasePath: map.getString('unary_use_case_path', _CoreDefaults.corePackagePath),

      nullaryUseCaseName: map.getString('nullary_use_case_name', _CoreDefaults.nullaryUseCaseName),
      nullaryUseCasePath: map.getString('nullary_use_case_path', _CoreDefaults.corePackagePath),

      repositoryBaseName: map.getString('repository_base_name', _CoreDefaults.repositoryBaseName),
      repositoryBasePath: map.getString('repository_base_path', _CoreDefaults.corePackagePath),
    );
  }
}*/

/// A private class to hold the default values for the core package.
class _CoreDefaults {
  static const corePackagePath = 'package:clean_architecture_core/clean_architecture_core.dart';
  static const entityBaseName = 'Entity';
  static const unaryUseCaseName = 'UnaryUseCase';
  static const nullaryUseCaseName = 'NullaryUseCase';
  static const repositoryBaseName = 'Repository';
}
