import 'package:clean_architecture_kit/clean_architecture_kit.dart';
import 'package:clean_architecture_kit/src/lints/disallow_entity_in_data_source.dart';
import 'package:clean_architecture_kit/src/lints/disallow_flutter_imports_in_domain.dart';
import 'package:clean_architecture_kit/src/lints/disallow_flutter_types_in_domain.dart';
import 'package:clean_architecture_kit/src/lints/disallow_model_in_domain.dart';
import 'package:clean_architecture_kit/src/lints/disallow_model_return_from_repository.dart';
import 'package:clean_architecture_kit/src/lints/disallow_repository_in_presentation.dart';
import 'package:clean_architecture_kit/src/lints/disallow_use_case_in_widget.dart';
import 'package:clean_architecture_kit/src/lints/enforce_abstract_data_source_dependency.dart';
import 'package:clean_architecture_kit/src/lints/enforce_custom_return_type.dart';
import 'package:clean_architecture_kit/src/lints/enforce_file_and_folder_location.dart';
import 'package:clean_architecture_kit/src/lints/enforce_layer_independence.dart';
import 'package:clean_architecture_kit/src/lints/enforce_model_to_entity_mapping.dart';
import 'package:clean_architecture_kit/src/lints/enforce_naming_conventions.dart';
import 'package:clean_architecture_kit/src/lints/enforce_repository_inheritance.dart';
import 'package:clean_architecture_kit/src/lints/enforce_use_case_inheritance.dart';
import 'package:clean_architecture_kit/src/lints/missing_use_case.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

void main() {
  group('CleanArchitectureKitPlugin', () {
    test('getLintRules should return an empty list when config is missing', () {
      // ARRANGE
      final plugin = CleanArchitectureKitPlugin();
      const emptyConfigs = CustomLintConfigs(
        rules: {},
        enableAllLintRules: false,
        debug: false,
        verbose: false,
      );

      // ACT
      final lintRules = plugin.getLintRules(emptyConfigs);

      // ASSERT
      expect(lintRules, isEmpty);
    });

    test('getLintRules should return an empty list when config json is empty', () {
      // ARRANGE
      final plugin = CleanArchitectureKitPlugin();

      // Use the correct constructor with an empty map and enabled: true
      const configsWithEmptyRule = CustomLintConfigs(
        rules: {'clean_architecture': LintOptions.fromYaml({}, enabled: true)},
        enableAllLintRules: false,
        debug: false,
        verbose: false,
      );

      // ACT
      final lintRules = plugin.getLintRules(configsWithEmptyRule);

      // ASSERT
      // The plugin's guard clause `if (rawConfig.isEmpty)` should catch this.
      expect(lintRules, isEmpty);
    });

    test('getLintRules should return all lints when config is provided', () {
      // ARRANGE
      final plugin = CleanArchitectureKitPlugin();
      final minimalConfigMap = {'project_structure': 'feature_first'};

      // ▼▼▼ THE DEFINITIVE FIX IS HERE ▼▼▼
      // We must use the internal `.fromYaml` constructor and provide the `enabled` flag.
      // This perfectly simulates a user providing a configuration block in their YAML.
      final configs = CustomLintConfigs(
        rules: {'clean_architecture': LintOptions.fromYaml(minimalConfigMap, enabled: true)},
        enableAllLintRules: false,
        debug: false,
        verbose: false,
      );

      // ACT
      final lintRules = plugin.getLintRules(configs);

      // ASSERT
      expect(lintRules, isNotEmpty);
      expect(lintRules, hasLength(16));

      expect(lintRules, [
        isA<DisallowModelInDomain>(),
        isA<DisallowEntityInDataSource>(),
        isA<DisallowRepositoryInPresentation>(),
        isA<DisallowModelReturnFromRepository>(),
        isA<DisallowFlutterImportsInDomain>(),
        isA<DisallowFlutterTypesInDomain>(),
        isA<DisallowUseCaseInWidget>(),
        isA<EnforceModelToEntityMapping>(),
        isA<EnforceLayerIndependence>(),
        isA<EnforceAbstractDataSourceDependency>(),
        isA<EnforceFileAndFolderLocation>(),
        isA<EnforceNamingConventions>(),
        isA<EnforceCustomReturnType>(),
        isA<EnforceUseCaseInheritance>(),
        isA<EnforceRepositoryInheritance>(),
        isA<MissingUseCase>(),
      ]);
    });
  });
}
