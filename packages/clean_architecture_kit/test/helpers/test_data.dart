import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';

CleanArchitectureConfig makeConfig({
  List<String>? domainRepositoriesPaths,
  List<String>? domainUseCasesPaths,
  List<String>? domainEntitiesPaths,
  String? projectStructure,
  String? featuresRootPath,
}) {
  final configMap = <String, dynamic>{
    'project_structure': projectStructure ?? 'feature_first',
    'feature_first_paths': {
      'features_root': featuresRootPath ?? 'features',
    },
    'layer_definitions': {
      'domain': {
        'repositories': domainRepositoriesPaths ?? ['repositories'],
        // ▼▼▼ THE FIX IS HERE ▼▼▼
        // The key should be 'usecases' to match 'entities', not 'use_cases'.
        'usecases': domainUseCasesPaths ?? ['usecases'],
        'entities': domainEntitiesPaths ?? ['entities'],
      },
      'data': {},
      'presentation': {},
    },
    'naming_conventions': {
      'repository_interface': '{{name}}Repository',
      'use_case': '{{name}}UseCase',
    },
    'type_safety': {},
    'inheritance': {},
    'generation_options': {},
  };
  return CleanArchitectureConfig.fromMap(configMap);
}
