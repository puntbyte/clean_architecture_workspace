import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';

CleanArchitectureConfig makeConfig({
  // Layer path overrides
  List<String>? domainRepositoriesPaths,
  List<String>? domainUseCasesPaths,
  List<String>? domainEntitiesPaths,

  // Naming convention overrides
  String? repositoryInterfaceNamingTemplate,
  String? useCaseNamingTemplate, // <-- ADD THIS
}) {
  final configMap = <String, dynamic>{
    'layer_definitions': {
      'domain': {
        'repositories': domainRepositoriesPaths ?? ['repositories'],
        'usecases': domainUseCasesPaths ?? ['usecases'],
        'entities': domainEntitiesPaths ?? ['entities'],
      },
      'data': {},
      'presentation': {},
    },
    'naming_conventions': {
      'repository_interface': repositoryInterfaceNamingTemplate ?? '{{name}}Repository',
      'use_case': useCaseNamingTemplate ?? '{{name}}Usecase', // <-- USE IT HERE
    },
    'type_safety': {},
    'inheritance': {},
    'generation_options': {},
  };
  return CleanArchitectureConfig.fromMap(configMap);
}
