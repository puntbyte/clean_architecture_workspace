import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that disallows the use of data-layer Models in domain-layer signatures.
///
/// This is the core purity rule for the domain layer's data structures, ensuring
/// it only deals with pure domain Entities.
class DisallowModelInDomain extends DartLintRule {
  static const _code = LintCode(
    name: 'disallow_model_in_domain',
    problemMessage:
        'Domain layer purity violation: Do not use a Model in a domain layer signature.',
    correctionMessage: 'Replace this Model with a pure domain Entity.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const DisallowModelInDomain({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final layer = layerResolver.getLayer(resolver.source.fullName);
    if (layer != ArchLayer.domain) return;

    void checkType(TypeAnnotation? typeNode) {
      if (typeNode == null) return;
      if (typeNode is! NamedType) return;

      final typeName = typeNode.name.lexeme;
      final modelTemplate = config.naming.model;

      if (NamingUtils.validateName(name: typeName, template: modelTemplate)) {
        reporter.atNode(typeNode, _code);
      }

      typeNode.typeArguments?.arguments.forEach(checkType);
    }

    context.registry.addMethodDeclaration((node) {
      checkType(node.returnType);
      node.parameters?.parameters.forEach((param) => checkType(_getParameterTypeNode(param)));
    });

    context.registry.addFieldDeclaration((node) {
      checkType(node.fields.type);
    });
  }

  TypeAnnotation? _getParameterTypeNode(FormalParameter parameter) {
    if (parameter is SimpleFormalParameter) return parameter.type;
    if (parameter is FieldFormalParameter) return parameter.type;
    if (parameter is SuperFormalParameter) return parameter.type;
    if (parameter is DefaultFormalParameter) return _getParameterTypeNode(parameter.parameter);
    return null;
  }
}
