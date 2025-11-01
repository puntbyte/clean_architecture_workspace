// lib/clean_architecture_kit.dart

// The main config class now directly represents the `clean_architecture` block.
import 'package:clean_architecture_kit/src/lints/data_source_purity.dart';
import 'package:clean_architecture_kit/src/lints/disallow_flutter_imports_in_domain.dart';
import 'package:clean_architecture_kit/src/lints/disallow_flutter_types_in_domain.dart';
import 'package:clean_architecture_kit/src/lints/domain_layer_purity.dart';
import 'package:clean_architecture_kit/src/lints/enforce_abstract_data_source_dependency.dart';
import 'package:clean_architecture_kit/src/lints/enforce_custom_return_type.dart';
import 'package:clean_architecture_kit/src/lints/enforce_file_and_folder_location.dart';
import 'package:clean_architecture_kit/src/lints/enforce_layer_independence.dart';
import 'package:clean_architecture_kit/src/lints/enforce_naming_conventions.dart';
import 'package:clean_architecture_kit/src/lints/enforce_repository_inheritance.dart';
import 'package:clean_architecture_kit/src/lints/enforce_use_case_inheritance.dart';
import 'package:clean_architecture_kit/src/lints/missing_use_case.dart';
import 'package:clean_architecture_kit/src/lints/presentation_layer_purity.dart';
import 'package:clean_architecture_kit/src/lints/repository_implementation_purity.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// This is the entry point for the plugin.
PluginBase createPlugin() => _CleanArchitectureKitPlugin();

/// The main plugin class for the `clean_architecture_kit` package.
class _CleanArchitectureKitPlugin extends PluginBase {
  /// This is the designated initialization method for lints.
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) {
    // 1. Read the user's configuration from their `analysis_options.yaml`.
    final rawConfig = Map<String, dynamic>.from(
      configs.rules['clean_architecture']?.json ?? {},
    );

    // 2. If the user hasn't provided the configuration block, we cannot proceed.
    //    Return an empty list to effectively disable all lints.
    if (rawConfig.isEmpty) return [];

    // 3. Parse the raw JSON map into a strongly-typed configuration object.
    final config = CleanArchitectureConfig.fromMap(rawConfig);

    // 4. Create a single LayerResolver instance to pass to all lints.
    final layerResolver = LayerResolver(config);

    // 5. Create and return the list of all lints, now using the local 'config' variable.
    return [
      // Purity Rules
      DomainLayerPurity(config: config, layerResolver: layerResolver),
      DataSourcePurity(config: config, layerResolver: layerResolver),
      PresentationLayerPurity(config: config, layerResolver: layerResolver),
      RepositoryImplementationPurity(config: config, layerResolver: layerResolver),
      DisallowFlutterImportsInDomain(config: config, layerResolver: layerResolver),
      DisallowFlutterTypesInDomain(config: config, layerResolver: layerResolver),

      // Dependency & Structure Rules
      EnforceLayerIndependence(config: config, layerResolver: layerResolver),
      EnforceAbstractDataSourceDependency(config: config, layerResolver: layerResolver),
      EnforceFileAndFolderLocation(config: config),

      // Naming, Type Safety & Inheritance Rules
      EnforceNamingConventions(config: config, layerResolver: layerResolver),
      EnforceCustomReturnType(config: config, layerResolver: layerResolver),
      EnforceUseCaseInheritance(config: config, layerResolver: layerResolver),
      EnforceRepositoryInheritance(config: config, layerResolver: layerResolver),

      // Code Generation Rule
      MissingUseCase(config: config, layerResolver: layerResolver),
    ];
  }
}
