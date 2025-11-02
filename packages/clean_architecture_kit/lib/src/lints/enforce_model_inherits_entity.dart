import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that enforces that a Model class must extend or implement its
/// corresponding domain Entity.
///
/// This ensures structural compatibility and makes the `toEntity()` mapping
/// process more robust and logical.
class EnforceModelInheritsEntity extends DartLintRule {
  static const _code = LintCode(
    name: 'enforce_model_inherits_entity',
    problemMessage: 'The model `{0}` must extend or implement the corresponding entity `{1}`.',
    correctionMessage: 'Add `extends {1}` or `implements {1}` to the class definition.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const EnforceModelInheritsEntity({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This lint should only run on files located in a model directory.
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.model) return;

    context.registry.addClassDeclaration((node) {
      final modelName = node.name.lexeme;
      final modelTemplate = config.naming.model;

      // First, check if the class is actually a Model according to the naming convention.
      if (!NamingUtils.validateName(name: modelName, template: modelTemplate)) {
        return;
      }

      // Infer the expected Entity name from the Model name.
      final entityTemplate = config.naming.entity;
      final baseName = _extractBaseName(modelName, modelTemplate);
      if (baseName == null) return; // Could not infer base name.

      final expectedEntityName = entityTemplate.replaceAll('{{name}}', baseName);

      // Check if the class extends or implements the expected Entity.
      var foundInheritance = false;

      // Check the 'extends' clause.
      final extendsClause = node.extendsClause;
      if (extendsClause != null && extendsClause.superclass.name.lexeme == expectedEntityName) {
        foundInheritance = true;
      }

      // If not found, check the 'implements' clause.
      if (!foundInheritance) {
        final implementsClause = node.implementsClause;
        if (implementsClause != null) {
          for (final interface in implementsClause.interfaces) {
            if (interface.name.lexeme == expectedEntityName) {
              foundInheritance = true;
              break;
            }
          }
        }
      }

      // If, after checking both, no valid inheritance was found, report a violation.
      if (!foundInheritance) {
        reporter.atToken(node.name, _code, arguments: [modelName, expectedEntityName]);
      }
    });
  }

  /// Extracts the base name from a class name based on a template.
  /// Example: 'UserModel' with '{{name}}Model' -> 'User'
  String? _extractBaseName(String name, String template) {
    if (template.isEmpty) return null;
    final pattern = template.replaceAll('{{name}}', '([A-Z][a-zA-Z0-9]+)');
    final regex = RegExp('^$pattern\$');
    final match = regex.firstMatch(name);
    return match?.group(1);
  }
}