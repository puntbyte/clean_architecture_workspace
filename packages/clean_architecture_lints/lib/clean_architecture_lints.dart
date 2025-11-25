// lib/clean_architecture_lints.dart

import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_custom_inheritance.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_entity_contract.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_port_contract.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_repository_contract.dart';
import 'package:clean_architecture_lints/src/lints/contract/enforce_usecase_contract.dart';
import 'package:clean_architecture_lints/src/lints/dependency/disallow_dependency_instantiation.dart';
import 'package:clean_architecture_lints/src/lints/dependency/disallow_repository_in_presentation.dart';
import 'package:clean_architecture_lints/src/lints/dependency/disallow_service_locator.dart';
import 'package:clean_architecture_lints/src/lints/dependency/disallow_use_case_in_widget.dart';
import 'package:clean_architecture_lints/src/lints/dependency/enforce_abstract_data_source_dependency.dart';
import 'package:clean_architecture_lints/src/lints/dependency/enforce_abstract_repository_dependency.dart';
import 'package:clean_architecture_lints/src/lints/dependency/enforce_layer_independence.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/disallow_throwing_from_repository.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/enforce_exception_on_data_source.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/enforce_try_catch_in_repository.dart';
import 'package:clean_architecture_lints/src/lints/location/enforce_file_and_folder_location.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_naming_antipattern.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_naming_pattern.dart';
import 'package:clean_architecture_lints/src/lints/naming/enforce_semantic_naming.dart';
import 'package:clean_architecture_lints/src/lints/purity/disallow_entity_in_data_source.dart';
import 'package:clean_architecture_lints/src/lints/purity/disallow_flutter_in_domain.dart';
import 'package:clean_architecture_lints/src/lints/purity/disallow_model_in_domain.dart';
import 'package:clean_architecture_lints/src/lints/purity/disallow_model_return_from_repository.dart';
import 'package:clean_architecture_lints/src/lints/purity/enforce_contract_api.dart';
import 'package:clean_architecture_lints/src/lints/purity/require_to_entity_method.dart';
import 'package:clean_architecture_lints/src/lints/structure/enforce_annotations.dart';
import 'package:clean_architecture_lints/src/lints/structure/enforce_type_safety.dart';
import 'package:clean_architecture_lints/src/lints/structure/missing_use_case.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/nlp/language_analyzer.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dictionaryx/dictionary_msa.dart';

/// The entry point for the `clean_architecture_lints` plugin.
PluginBase createPlugin() => CleanArchitectureLintsPlugin();

/// The main plugin class that initializes and provides all architectural lint rules.
class CleanArchitectureLintsPlugin extends PluginBase {
  /// This method is called once per analysis run to create the list of lint rules.
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    // 1. Read and parse the user's configuration from `analysis_options.yaml`.
    // If the config block is missing, we return an empty list to disable all lints.
    final rawConfig = Map<String, dynamic>.from(configs.rules['clean_architecture']?.json ?? {});
    if (rawConfig.isEmpty) return [];
    final config = ArchitectureConfig.fromMap(rawConfig);

    // 2. Create shared instances of core utilities.
    // These are created once and passed to all lints to ensure consistency and performance.
    final resolver = LayerResolver(config);
    final analyzer = LanguageAnalyzer(dictionary: DictionaryMSA());

    // 3. Define the lint rules in logical groups for excellent readability and maintenance.
    final contractRules = [
      EnforceCustomInheritance(config: config, layerResolver: resolver),
      EnforceEntityContract(config: config, layerResolver: resolver),
      EnforcePortContract(config: config, layerResolver: resolver),
      EnforceRepositoryContract(config: config, layerResolver: resolver),
      EnforceUsecaseContract(config: config, layerResolver: resolver),
    ];

    final dependencyRules = [
      DisallowDependencyInstantiation(config: config, layerResolver: resolver),
      DisallowRepositoryInPresentation(config: config, layerResolver: resolver),
      DisallowServiceLocator(config: config, layerResolver: resolver),
      DisallowUseCaseInWidget(config: config, layerResolver: resolver),
      EnforceAbstractDataSourceDependency(config: config, layerResolver: resolver),
      EnforceAbstractRepositoryDependency(config: config, layerResolver: resolver),
      EnforceLayerIndependence(config: config, layerResolver: resolver),
    ];

    final errorHandlingRules = [
      DisallowThrowingFromRepository(config: config, layerResolver: resolver),
      EnforceExceptionOnDataSource(config: config, layerResolver: resolver),
      EnforceTryCatchInRepository(config: config, layerResolver: resolver),
    ];

    final locationRules = [
      EnforceFileAndFolderLocation(config: config, layerResolver: resolver),
    ];

    final namingRules = [
      EnforceNamingAntipattern(config: config, layerResolver: resolver),
      EnforceNamingPattern(config: config, layerResolver: resolver),
      EnforceSemanticNaming(config: config, layerResolver: resolver, analyzer: analyzer),
    ];

    final purityRules = [
      DisallowEntityInDataSource(config: config, layerResolver: resolver),
      DisallowFlutterInDomain(config: config, layerResolver: resolver),
      DisallowModelInDomain(config: config, layerResolver: resolver),
      DisallowModelReturnFromRepository(config: config, layerResolver: resolver),
      EnforceContractApi(config: config, layerResolver: resolver),
      RequireToEntityMethod(config: config, layerResolver: resolver),
    ];

    final structureRules = [
      EnforceAnnotations(config: config, layerResolver: resolver),
      EnforceTypeSafety(config: config, layerResolver: resolver),
      MissingUseCase(config: config, layerResolver: resolver),
    ];

    // 4. Combine all groups into a single list using the spread operator.
    return [
      ...contractRules,
      ...dependencyRules,
      ...errorHandlingRules,
      ...locationRules,
      ...namingRules,
      ...purityRules,
      ...structureRules,
    ];
  }
}
