import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/fixes/create_to_entity_mapping_fix.dart'; // <-- ADD THIS IMPORT
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceModelToEntityMapping extends DartLintRule {
  static const _code = LintCode(
    name: 'enforce_model_to_entity_mapping',
    problemMessage: 'Models must have a `toEntity()` conversion method.',
    correctionMessage: 'Add a method `YourEntity toEntity()` to this model, or create a mapping '
        'extension.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const EnforceModelToEntityMapping({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  List<Fix> getFixes() => [CreateToEntityMappingFix(config: config)];

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.model) return;

    context.registry.addClassDeclaration((node) {
      final modelTemplate = config.naming.model;
      if (!NamingUtils.validateName(name: node.name.lexeme, template: modelTemplate)) return;

      var hasToEntityMethod = false;
      for (final member in node.members) {
        if (member is MethodDeclaration && member.name.lexeme == 'toEntity') {
          hasToEntityMethod = true;
          break;
        }
      }

      if (!hasToEntityMethod) reporter.atToken(node.name, _code);
    });
  }
}
