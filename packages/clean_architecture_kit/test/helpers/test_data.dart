// test/helpers/test_data.dart
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/models/rules/parameter_rule.dart';
import 'package:clean_architecture_kit/src/models/rules/return_rule.dart';

/// A single, powerful test data factory for creating a complete and valid
/// [CleanArchitectureConfig] object for use in unit tests.
///
/// It provides sensible defaults for all configuration options, and allows any
/// specific property to be overridden by passing it as a parameter.
CleanArchitectureConfig makeConfig({
  // Top-level structure
  String projectStructure = 'feature_first',

  // Feature-first paths
  String featuresRoot = 'features',

  // Layer-first paths
  String domainPath = 'domain',
  String dataPath = 'data',
  String presentationPath = 'presentation',

  // Layer definitions
  List<String> domainEntitiesPaths = const ['entities'],
  List<String> domainRepositoriesPaths = const ['contracts'],
  List<String> domainUseCasesPaths = const ['usecases'],
  List<String> dataModelsPaths = const ['models'],
  List<String> dataDataSourcesPaths = const ['sources'],
  List<String> dataRepositoriesPaths = const ['repositories'],
  List<String> presentationManagersPaths = const ['managers'],
  List<String> presentationWidgetsPaths = const ['widgets'],
  List<String> presentationPagesPaths = const ['pages'],

  // Naming conventions (use `dynamic` to accept both String and Map)
  dynamic entityNaming = '{{name}}',
  dynamic modelNaming = '{{name}}Model',
  dynamic useCaseNaming = '{{name}}',
  dynamic useCaseRecordParameterNaming = '_{{name}}Params',
  dynamic repositoryInterfaceNaming = '{{name}}Repository',
  dynamic repositoryImplementationNaming = '{{type}}{{name}}Repository',
  dynamic dataSourceInterfaceNaming = '{{name}}DataSource',
  dynamic dataSourceImplementationNaming = 'Default{{name}}DataSource',

  // Type safety
  List<ReturnRule> returnRules = const [],
  List<ParameterRule> parameterRules = const [],

  // Inheritance
  String entityBaseName = 'Entity',
  String entityBasePath = 'package:example/core/entity/entity.dart',
  String repositoryBaseName = 'Repository',
  String repositoryBasePath = 'package:example/core/repository/repository.dart',
  String unaryUseCaseName = 'UnaryUsecase',
  String unaryUseCasePath = 'package:example/core/usecase/usecase.dart',
  String nullaryUseCaseName = 'NullaryUsecase',
  String nullaryUseCasePath = 'package:example/core/usecase/usecase.dart',

  // Services
  List<String> serviceLocatorNames = const ['getIt', 'locator', 'sl'],
  List<Map<String, String>> useCaseAnnotations = const [],
}) {
  // This map literal is a complete and valid representation of the YAML structure.
  return CleanArchitectureConfig.fromMap({
    'project_structure': projectStructure,
    'feature_first_paths': {'features_root': featuresRoot},

    'layer_first_paths': {
      'domain': domainPath,
      'data': dataPath,
      'presentation': presentationPath,
    },

    'layer_definitions': {
      'domain': {
        'entities': domainEntitiesPaths,
        'repositories': domainRepositoriesPaths,
        'use_cases': domainUseCasesPaths,
      },

      'data': {
        'models': dataModelsPaths,
        'data_sources': dataDataSourcesPaths,
        'repositories': dataRepositoriesPaths,
      },

      'presentation': {
        'managers': presentationManagersPaths,
        'widgets': presentationWidgetsPaths,
        'pages': presentationPagesPaths,
      },
    },

    'naming_conventions': {
      'entity': entityNaming,
      'model': modelNaming,
      'use_case': useCaseNaming,
      'use_case_record_parameter': useCaseRecordParameterNaming,
      'repository_interface': repositoryInterfaceNaming,
      'repository_implementation': repositoryImplementationNaming,
      'data_source_interface': dataSourceInterfaceNaming,
      'data_source_implementation': dataSourceImplementationNaming,
    },

    'type_safety': {
      'returns': returnRules.map((r) => {
        'type': r.type,
        'where': r.where,
        if (r.importPath != null) 'import': r.importPath,
      }).toList(),
      'parameters': parameterRules.map((p) => {
        'type': p.type,
        'where': p.where,
        if (p.importPath != null) 'import': p.importPath,
        if (p.identifier != null) 'identifier': p.identifier,
      }).toList(),
    },

    'inheritance': {
      'entity_base_name': entityBaseName,
      'entity_base_path': entityBasePath,
      'repository_base_name': repositoryBaseName,
      'repository_base_path': repositoryBasePath,
      'unary_use_case_name': unaryUseCaseName,
      'unary_use_case_path': unaryUseCasePath,
      'nullary_use_case_name': nullaryUseCaseName,
      'nullary_use_case_path': nullaryUseCasePath,
    },

    'services': {
      'dependency_injection': {
        'service_locator_names': serviceLocatorNames,
        'use_case_annotations': useCaseAnnotations,
      }
    },
  });
}
