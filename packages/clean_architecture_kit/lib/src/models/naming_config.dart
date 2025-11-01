// lib/src/models/naming_config.dart

class NamingConfig {
  final String entity;
  final String model;
  final String useCase;
  final String useCaseRecordParameter;
  final String repositoryInterface;
  final String repositoryImplementation;
  final String dataSourceInterface;
  final String dataSourceImplementation;

  const NamingConfig({
    required this.entity,
    required this.model,
    required this.useCase,
    required this.useCaseRecordParameter,
    required this.repositoryInterface,
    required this.repositoryImplementation,
    required this.dataSourceInterface,
    required this.dataSourceImplementation,
  });

  factory NamingConfig.fromMap(Map<String, dynamic> map) {
    return NamingConfig(
      entity: map['entity'] as String? ?? '{{name}}',
      model: map['model'] as String? ?? '{{name}}Model',

      useCase: map['use_case'] as String? ?? '{{name}}Usecase',
      useCaseRecordParameter: map['use_case_record_parameter'] as String? ?? '_{{name}}Parameter',

      repositoryInterface: map['repository_interface'] as String? ?? '{{name}}Repository',
      repositoryImplementation: map['repository_implementation'] as String?
          ?? '{{name}}RepositoryImpl',

      dataSourceInterface: map['data_source_interface'] as String? ?? '{{name}}DataSource',
      dataSourceImplementation: map['data_source_implementation'] as String?
          ?? '{{name}}DataSourceImpl',
    );
  }
}
