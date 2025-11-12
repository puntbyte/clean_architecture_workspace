// lib/clean_architecture_lints.dart

import 'package:clean_architecture_lints/src/analysis/component_resolver.dart';
import 'package:clean_architecture_lints/src/lints/dependency/disallow_service_locator.dart';
import 'package:clean_architecture_lints/src/lints/error_handling/disallow_throwing_from_repository.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/natural_language_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dictionaryx/dictionary_msa.dart';

/// The entry point for the `clean_architecture_lints` plugin.
PluginBase createPlugin() => CleanArchitectureLintsPlugin();

/// The main plugin class that initializes and provides all architectural lint rules.
class CleanArchitectureLintsPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    // 1. Read and parse the user's configuration from `analysis_options.yaml`.
    // The key in the YAML is still 'clean_architecture' for user convenience and backward compatibility.
    final rawConfig = Map<String, dynamic>.from(configs.rules['clean_architecture']?.json ?? {});
    if (rawConfig.isEmpty) return [];

    // Use the new, correctly named config class.
    final config = ArchitectureConfig.fromMap(rawConfig);

    // 2. Create shared instances of core utilities.
    final componentResolver = ComponentResolver(config);
    final nlpUtils = NaturalLanguageUtils(dictionary: DictionaryMSA());

    // 3. Define and return the list of all available lints.
    // Lints that have not yet been updated to use the new ComponentResolver
    // are commented out, providing a clear to-do list.
    return [
      // === UPDATED AND READY ===
      DisallowThrowingFromRepository(config: config, componentResolver: componentResolver),
      DisallowServiceLocator(config: config, componentResolver: componentResolver),

      // === PENDING REFACTOR (Commented Out) ===

      // -- Contract Lints --
      // EnforceEntityContract(config: config, componentResolver: componentResolver),
      // EnforceRepositoryContract(config: config, componentResolver: componentResolver),
      // EnforceUseCaseContract(config: config, componentResolver: componentResolver),

      // -- Dependency Lints --
      // DisallowDependencyInstantiation(config: config, componentResolver: componentResolver),
      // DisallowRepositoryInPresentation(config: config, componentResolver: componentResolver),
      // DisallowUseCaseInWidget(config: config, componentResolver: componentResolver),
      // EnforceAbstractDataSourceDependency(config: config, componentResolver: componentResolver),
      // EnforceAbstractRepositoryDependency(config: config, componentResolver: componentResolver),

      // -- Error Handling Lints --
      // EnforceExceptionOnDataSource(config: config, componentResolver: componentResolver),
      // EnforceTryCatchInRepository(config: config, componentResolver: componentResolver),

      // -- Generation Lints --
      // MissingUseCase(config: config, componentResolver: componentResolver),

      // -- Location Lints --
      // EnforceFileAndFolderLocation(config: config, componentResolver: componentResolver),
      // EnforceLayerIndependence(config: config, componentResolver: componentResolver),

      // -- Purity Lints --
      // DisallowEntityInDataSource(config: config, componentResolver: componentResolver),
      // DisallowFlutterInDomain(config: config, componentResolver: componentResolver),
      // DisallowModelInDomain(config: config, componentResolver: componentResolver),
      // DisallowModelReturnFromRepository(config: config, componentResolver: componentResolver),

      // -- Structure & Naming Lints --
      // DisallowPublicMembersInImplementation(config: config, componentResolver: componentResolver),
      // EnforceAnnotations(config: config, componentResolver: componentResolver),
      // EnforceInheritance(config: config, componentResolver: componentResolver), // This will replace the 3 contract lints
      // EnforceModelInheritsEntity(config: config, componentResolver: componentResolver),
      // EnforceModelToEntityMapping(config: config, componentResolver: componentResolver),
      // EnforceNamingConventions(config: config, componentResolver: componentResolver),
      // EnforceRepositoryImplementationContract(config: config, componentResolver: componentResolver),
      // EnforceSemanticNaming(config: config, componentResolver: componentResolver, nlpUtils: nlpUtils),
      // EnforceTypeSafety(config: config, componentResolver: componentResolver),
    ];
  }
}
