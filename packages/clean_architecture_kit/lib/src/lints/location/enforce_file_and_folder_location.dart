// lib/src/lints/location/enforce_file_and_folder_location.dart

import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that enforces that files are in the correct directory based on the class name and
/// its architectural role.
class EnforceFileAndFolderLocation extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_file_and_folder_location',
    problemMessage: 'A {0} was found in a "{1}" directory, but it belongs in a "{2}" directory.',
    correctionMessage: 'Move the file to a directory that matches the configured paths.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceFileAndFolderLocation({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final actualSubLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (actualSubLayer == ArchSubLayer.unknown) return;

    final locationRules = _getLocationRules();

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final isClassAbstract = node.abstractKeyword != null;

      // 1. Find ALL possible architectural types this class could be, based on its name.
      final possibleRules = locationRules
          .where((rule) => NamingUtils.validateName(name: className, template: rule.namingTemplate))
          .toList();

      if (possibleRules.isEmpty) return;

      // 2. THE CRITICAL FIX: Use the `abstract` keyword to resolve ambiguity.
      // If a class is abstract, it cannot be an "Implementation".
      // If it's concrete, it cannot be an "Interface".
      possibleRules.removeWhere((rule) => rule.isInterface != isClassAbstract);

      // If after filtering, no valid rules remain, we can't make a judgment.
      if (possibleRules.isEmpty) return;

      // 3. The class is correctly placed if its actual location is one of the possible expected
      // locations.
      final isLocationValid = possibleRules.any((rule) => rule.expectedSubLayer == actualSubLayer);

      // 4. If the location is NOT valid, it's a true violation.
      if (!isLocationValid) {
        // Report the error using the first valid rule as the best guess.
        final bestGuessRule = possibleRules.first;
        reporter.atToken(
          node.name,
          _code,
          arguments: [
            bestGuessRule.classType,
            actualSubLayer.name,
            bestGuessRule.expectedSubLayer.name,
          ],
        );
      }
    });
  }

  List<_LocationRule> _getLocationRules() => <_LocationRule>[
    _LocationRule(
      classType: 'Entity',
      namingTemplate: config.naming.entity.pattern,
      expectedSubLayer: ArchSubLayer.entity,
    ),

    _LocationRule(
      classType: 'Model',
      namingTemplate: config.naming.model.pattern,
      expectedSubLayer: ArchSubLayer.model,
    ),

    _LocationRule(
      classType: 'UseCase',
      namingTemplate: config.naming.useCase.pattern,
      expectedSubLayer: ArchSubLayer.useCase,
    ),

    _LocationRule(
      classType: 'Repository Interface',
      namingTemplate: config.naming.repository.pattern,
      expectedSubLayer: ArchSubLayer.domainRepository,
      isInterface: true,
    ),

    _LocationRule(
      classType: 'Repository Implementation',
      namingTemplate: config.naming.repositoryImplementation.pattern,
      expectedSubLayer: ArchSubLayer.dataRepository,
    ),

    _LocationRule(
      classType: 'DataSource Interface',
      namingTemplate: config.naming.dataSource.pattern,
      expectedSubLayer: ArchSubLayer.dataSource,
      isInterface: true,
    ),

    _LocationRule(
      classType: 'DataSource Implementation',
      namingTemplate: config.naming.dataSourceImplementation.pattern,
      expectedSubLayer: ArchSubLayer.dataSource,
    ),
  ];
}

/// A private helper class to associate a class "type" with its expected location.
class _LocationRule {
  /// A user-friendly name for the class type (e.g., "Model").
  final String classType;

  /// The naming convention that identifies this class type.
  final String namingTemplate;

  /// The architectural sub-layer where this class type is expected to be located.
  final ArchSubLayer expectedSubLayer;

  // A new flag to distinguish interfaces from implementations.
  final bool isInterface;

  const _LocationRule({
    required this.classType,
    required this.namingTemplate,
    required this.expectedSubLayer,
    this.isInterface = false,
  });
}
