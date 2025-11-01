import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class DataSourcePurity extends DartLintRule {
  static const _code = LintCode(
    name: 'data_source_purity',
    problemMessage: 'DataSource purity violation: DataSources should not use domain Entities.',
    correctionMessage:
        'DataSources should return Models/DTOs, not Entities. The repository '
        'implementation is responsible for mapping.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const DataSourcePurity({required this.config, required this.layerResolver}) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataSource) return;

    void checkType(TypeAnnotation? typeNode) {
      if (typeNode == null) return;
      final type = typeNode.type;
      if (type == null) return;
      if (_isDomainEntity(type)) reporter.atNode(typeNode, _code);
    }

    context.registry.addMethodDeclaration((node) {
      checkType(node.returnType);
      node.parameters?.parameters.forEach((param) => checkType(_getParameterTypeNode(param)));
    });
  }

  bool _isDomainEntity(DartType type) {
    final library = type.element?.library;
    if (library != null) {
      final sourcePath = library.firstFragment.source.fullName;
      final typeLayer = layerResolver.getLayer(sourcePath);

      if (typeLayer == ArchLayer.domain) {
        final pathSegments = sourcePath.replaceAll(r'\', '/').split('/');

        final entityDirs = config.layers.domainEntitiesPaths;

        if (entityDirs.any(pathSegments.contains)) return true;
      }
    }

    if (type is InterfaceType && type.typeArguments.isNotEmpty) {
      return type.typeArguments.any(_isDomainEntity);
    }

    return false;
  }

  TypeAnnotation? _getParameterTypeNode(FormalParameter parameter) {
    if (parameter is SimpleFormalParameter) return parameter.type;
    if (parameter is FieldFormalParameter) return parameter.type;
    if (parameter is SuperFormalParameter) return parameter.type;
    if (parameter is DefaultFormalParameter) return _getParameterTypeNode(parameter.parameter);

    return null;
  }
}
