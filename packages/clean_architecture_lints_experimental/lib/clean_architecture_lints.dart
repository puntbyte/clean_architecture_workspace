// lib/clean_architecture_lints.dart

import 'dart:convert';
import 'dart:io';

import 'package:architecture_lints/src/analysis/layer_resolver.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/lints/contract/enforce_custom_inheritance.dart';
import 'package:architecture_lints/src/lints/contract/enforce_entity_contract.dart';
import 'package:architecture_lints/src/lints/contract/enforce_port_contract.dart';
import 'package:architecture_lints/src/lints/contract/enforce_repository_contract.dart';
import 'package:architecture_lints/src/lints/contract/enforce_usecase_contract.dart';
import 'package:architecture_lints/src/lints/dependency/'
    'disallow_dependency_instantiation.dart';
import 'package:architecture_lints/src/lints/dependency/'
    'disallow_repository_in_presentation.dart';
import 'package:architecture_lints/src/lints/dependency/disallow_service_locator.dart';
import 'package:architecture_lints/src/lints/dependency/disallow_use_case_in_widget.dart';
import 'package:architecture_lints/src/lints/dependency/'
    'enforce_abstract_data_source_dependency.dart';
import 'package:architecture_lints/src/lints/dependency/'
    'enforce_abstract_repository_dependency.dart';
import 'package:architecture_lints/src/lints/dependency/enforce_layer_independence.dart';
import 'package:architecture_lints/src/lints/error_handling/'
    'disallow_throwing_from_repository.dart';
import 'package:architecture_lints/src/lints/error_handling/'
    'enforce_exception_on_data_source.dart';
import 'package:architecture_lints/src/lints/error_handling/'
    'enforce_try_catch_in_repository.dart';
import 'package:architecture_lints/src/lints/location/enforce_file_and_folder_location.dart';
import 'package:architecture_lints/src/lints/naming/enforce_naming_antipattern.dart';
import 'package:architecture_lints/src/lints/naming/enforce_naming_pattern.dart';
import 'package:architecture_lints/src/lints/naming/enforce_semantic_naming.dart';
import 'package:architecture_lints/src/lints/purity/disallow_entity_in_data_source.dart';
import 'package:architecture_lints/src/lints/purity/disallow_flutter_in_domain.dart';
import 'package:architecture_lints/src/lints/purity/disallow_model_in_domain.dart';
import 'package:architecture_lints/src/lints/purity/enforce_contract_api.dart';
import 'package:architecture_lints/src/lints/purity/require_to_entity_method.dart';
import 'package:architecture_lints/src/lints/structure/enforce_annotations.dart';
import 'package:architecture_lints/src/lints/structure/missing_use_case.dart';
import 'package:architecture_lints/src/lints/type_safety/'
    'disallow_model_return_from_repository.dart';
import 'package:architecture_lints/src/lints/type_safety/enforce_type_safety.dart';
import 'package:architecture_lints/src/models/configs/architecture_config.dart';
import 'package:architecture_lints/src/utils/nlp/language_analyzer.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dictionaryx/dictionary_msa.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// The entry point for the `clean_architecture_lints` plugin.
PluginBase createPlugin() => CleanArchitectureLintsPlugin();

/// The main plugin class that initializes and provides all architectural lint rules.
class CleanArchitectureLintsPlugin extends PluginBase {
  /// This method is called once per analysis run to create the list of lint rules.
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    // 1. Get the raw config from analysis_options.yaml
    var rawConfig = Map<String, dynamic>.from(configs.rules['clean_architecture']?.json ?? {});

    // 2. Check for External Config File
    // If 'config_file' is present, we load that file and use it as the source of truth.
    if (rawConfig.containsKey('config_file')) {
      final configPath = rawConfig['config_file'] as String;
      final projectRoot = p.current; // Works because linter runs in project root context usually
      final file = File(p.join(projectRoot, configPath));

      if (file.existsSync()) {
        try {
          final yamlString = file.readAsStringSync();
          final yamlMap = loadYaml(yamlString);
          // Convert YamlMap to Map<String, dynamic> via JSON encoding to ensure type safety
          rawConfig = jsonDecode(jsonEncode(yamlMap)) as Map<String, dynamic>;
        } catch (e) {
          // If parsing fails, we fall back to empty or throw.
          // For a linter, it's safer to return empty list or log print (though print is swallowed).
          // We proceed with empty rules to avoid crashing the analysis server.
          return [];
        }
      }
    }

    // If config is empty at this point, disable lints.
    if (rawConfig.isEmpty) return [];
    final config = ArchitectureConfig.fromMap(rawConfig);

    // 3. Initialize Shared Utilities
    final resolver = LayerResolver(config);
    final analyzer = LanguageAnalyzer(dictionary: DictionaryMSA());

    // 4. Combine all groups into a single list using the spread operator.
    return [
      ..._contractRules(config, resolver),
      ..._dependencyRules(config, resolver),
      ..._errorHandlingRules(config, resolver),
      ..._locationRules(config, resolver),
      ..._namingRules(config, resolver, analyzer),
      ..._purityRules(config, resolver),
      ..._structureRules(config, resolver),
    ];
  }

  List<ArchitectureRule> _dependencyRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    DisallowDependencyInstantiation(definition: config, layerResolver: resolver),
    DisallowRepositoryInPresentation(definition: config, layerResolver: resolver),
    DisallowServiceLocator(definition: config, layerResolver: resolver),
    DisallowUseCaseInWidget(definition: config, layerResolver: resolver),
    EnforceAbstractDataSourceDependency(definition: config, layerResolver: resolver),
    EnforceAbstractRepositoryDependency(definition: config, layerResolver: resolver),
    EnforceLayerIndependence(definition: config, layerResolver: resolver),
  ];

  List<ArchitectureRule> _contractRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    EnforceCustomInheritance(definition: config, layerResolver: resolver),
    EnforceEntityContract(definition: config, layerResolver: resolver),
    EnforcePortContract(definition: config, layerResolver: resolver),
    EnforceRepositoryContract(definition: config, layerResolver: resolver),
    EnforceUsecaseContract(definition: config, layerResolver: resolver),
  ];

  List<ArchitectureRule> _errorHandlingRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    DisallowThrowingFromRepository(definition: config, layerResolver: resolver),
    EnforceExceptionOnDataSource(definition: config, layerResolver: resolver),
    EnforceTryCatchInRepository(definition: config, layerResolver: resolver),
  ];

  List<ArchitectureRule> _locationRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    EnforceFileAndFolderLocation(definition: config, layerResolver: resolver),
  ];

  List<ArchitectureRule> _namingRules(
    ArchitectureConfig config,
    LayerResolver resolver,
    LanguageAnalyzer analyzer,
  ) => [
    EnforceNamingAntipattern(definition: config, layerResolver: resolver),
    EnforceNamingPattern(definition: config, layerResolver: resolver),
    EnforceSemanticNaming(definition: config, layerResolver: resolver, analyzer: analyzer),
  ];

  List<ArchitectureRule> _purityRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    DisallowEntityInDataSource(definition: config, layerResolver: resolver),
    DisallowFlutterInDomain(definition: config, layerResolver: resolver),
    DisallowModelInDomain(definition: config, layerResolver: resolver),
    DisallowModelReturnFromRepository(definition: config, layerResolver: resolver),
    EnforceContractApi(definition: config, layerResolver: resolver),
    RequireToEntityMethod(definition: config, layerResolver: resolver),
  ];

  List<ArchitectureRule> _structureRules(
    ArchitectureConfig config,
    LayerResolver resolver,
  ) => [
    EnforceAnnotations(definition: config, layerResolver: resolver),
    EnforceTypeSafety(definition: config, layerResolver: resolver),
    MissingUseCase(definition: config, layerResolver: resolver),
  ];
}
