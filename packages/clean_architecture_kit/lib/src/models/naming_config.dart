// lib/src/models/naming_config.dart

import 'package:clean_architecture_kit/src/models/rules/naming_rule.dart';

/// A strongly-typed representation of the `naming_conventions` block in `analysis_options.yaml`.
class NamingConfig {
  final NamingRule entity;
  final NamingRule model;
  final NamingRule useCase;
  final NamingRule useCaseParameter;

  final NamingRule dataSource;
  final NamingRule dataSourceImplementation;
  final NamingRule repository;
  final NamingRule repositoryImplementation;

  final NamingRule manager;
  final NamingRule event;
  final NamingRule eventImplementation;
  final NamingRule state;
  final NamingRule stateImplementation;

  const NamingConfig({
    required this.entity,
    required this.model,
    required this.useCase,
    required this.useCaseParameter,
    required this.dataSource,
    required this.dataSourceImplementation,
    required this.repository,
    required this.repositoryImplementation,
    required this.manager,
    required this.event,
    required this.eventImplementation,
    required this.state,
    required this.stateImplementation,
  });

  factory NamingConfig.fromMap(Map<String, dynamic> map) {
    return NamingConfig(
      entity: NamingRule.from(map['entity'], '{{name}}'),
      model: NamingRule.from(map['model'], '{{name}}Model'),
      useCase: NamingRule.from(map['use_case'], '{{name}}'),
      useCaseParameter: NamingRule.from(map['use_case_parameter'], '_{{name}}Param'),

      dataSource: NamingRule.from(map['data_source'], '{{name}}DataSource'),
      dataSourceImplementation: NamingRule.from(
        map['data_source_impl'],
        'Default{{name}}DataSource',
      ),
      repository: NamingRule.from(map['repository'], '{{name}}Repository'),
      repositoryImplementation: NamingRule.from(
        map['repository_impl'],
        '{{kind}}{{name}}Repository',
      ),

      manager: NamingRule.from(map['manager'], '{{name}}Bloc'),
      event: NamingRule.from(map['event'], '{{name}}Event'),
      eventImplementation: NamingRule.from(map['event_impl'], '{{name}}'),
      state: NamingRule.from(map['state'], '{{name}}State'),
      stateImplementation: NamingRule.from(map['state_impl'], '{{name}}'),
    );
  }
}
