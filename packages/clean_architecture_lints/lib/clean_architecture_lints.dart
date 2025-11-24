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
import 'package:clean_architecture_lints/src/utils/nlp/natural_language_utils.dart';
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
    final layerResolver = LayerResolver(config);
    final nlpUtils = NaturalLanguageUtils(dictionary: DictionaryMSA());

    // 3. Define the lint rules in logical groups for excellent readability and maintenance.
    final contractRules = [
      EnforceCustomInheritance(config: config, layerResolver: layerResolver),
      EnforceEntityContract(config: config, layerResolver: layerResolver),
      EnforcePortContract(config: config, layerResolver: layerResolver),
      EnforceRepositoryContract(config: config, layerResolver: layerResolver),
      EnforceUsecaseContract(config: config, layerResolver: layerResolver),
    ];

    final dependencyRules = [
      DisallowDependencyInstantiation(config: config, layerResolver: layerResolver),
      DisallowRepositoryInPresentation(config: config, layerResolver: layerResolver),
      DisallowServiceLocator(config: config, layerResolver: layerResolver),
      DisallowUseCaseInWidget(config: config, layerResolver: layerResolver),
      EnforceAbstractDataSourceDependency(config: config, layerResolver: layerResolver),
      EnforceAbstractRepositoryDependency(config: config, layerResolver: layerResolver),
      EnforceLayerIndependence(config: config, layerResolver: layerResolver),
    ];

    final errorHandlingRules = [
      DisallowThrowingFromRepository(config: config, layerResolver: layerResolver),
      EnforceExceptionOnDataSource(config: config, layerResolver: layerResolver),
      EnforceTryCatchInRepository(config: config, layerResolver: layerResolver),
    ];

    final locationRules = [
      EnforceFileAndFolderLocation(config: config, layerResolver: layerResolver),
    ];

    final namingRules = [
      EnforceNamingAntipattern(config: config, layerResolver: layerResolver),
      EnforceNamingPattern(config: config, layerResolver: layerResolver),
      EnforceSemanticNaming(config: config, layerResolver: layerResolver, nlpUtils: nlpUtils),
    ];

    final purityRules = [
      DisallowEntityInDataSource(config: config, layerResolver: layerResolver),
      DisallowFlutterInDomain(config: config, layerResolver: layerResolver),
      DisallowModelInDomain(config: config, layerResolver: layerResolver),
      DisallowModelReturnFromRepository(config: config, layerResolver: layerResolver),
      EnforceContractApi(config: config, layerResolver: layerResolver),
      RequireToEntityMethod(config: config, layerResolver: layerResolver),
    ];

    final structureRules = [
      EnforceAnnotations(config: config, layerResolver: layerResolver),
      EnforceTypeSafety(config: config, layerResolver: layerResolver),
      MissingUseCase(config: config, layerResolver: layerResolver),
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
