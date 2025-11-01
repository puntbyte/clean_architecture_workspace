import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that flags any usage of a type from the Flutter SDK within the
/// domain layer. This checks fields, method return types, and parameters.
class DisallowFlutterTypesInDomain extends DartLintRule {
  static const _code = LintCode(
    name: 'disallow_flutter_types_in_domain',
    problemMessage: 'Domain layer purity violation: Do not use types from the Flutter SDK.',
    correctionMessage: 'Replace this Flutter type with a pure Dart type or a domain Entity.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const DisallowFlutterTypesInDomain({required this.config, required this.layerResolver})
    : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final layer = layerResolver.getLayer(resolver.source.fullName);
    if (layer != ArchLayer.domain) return;

    // A helper to pass to the visitors.
    void checkType(TypeAnnotation? typeNode) {
      if (typeNode == null) return;

      // Get the fully resolved semantic type from the AST node.
      final type = typeNode.type;
      if (type == null) return;

      // Recursively check the type and its generic arguments.
      if (_isFlutterType(type)) {
        reporter.atNode(typeNode, _code);
      }
    }

    // Visit all method declarations to check return types and parameters.
    context.registry.addMethodDeclaration((node) {
      checkType(node.returnType);
      node.parameters?.parameters.forEach((param) => checkType(_getParameterTypeNode(param)));
    });

    // Visit all field declarations.
    context.registry.addFieldDeclaration((node) {
      checkType(node.fields.type);
    });

    // Visit all top-level variable declarations.
    context.registry.addTopLevelVariableDeclaration((node) {
      checkType(node.variables.type);
    });
  }

  /// Recursively checks if a type or any of its generic arguments originate from the Flutter SDK.
  bool _isFlutterType(DartType type) {
    final library = type.element?.library;
    if (library != null) {
      final uri = library.firstFragment.source.uri;
      // Check if the type's source URI is a package and if that package is 'flutter'.
      if (uri.isScheme('package') && uri.pathSegments.first == 'flutter') {
        return true;
      }
    }

    // If the type is generic (like List<Color>), recurse on its arguments.
    if (type is InterfaceType && type.typeArguments.isNotEmpty) {
      for (final arg in type.typeArguments) {
        if (_isFlutterType(arg)) {
          return true;
        }
      }
    }

    return false;
  }

  /// A robust helper to get the `TypeAnnotation` AST node from any kind of `FormalParameter`.
  TypeAnnotation? _getParameterTypeNode(FormalParameter parameter) {
    if (parameter is SimpleFormalParameter) return parameter.type;
    if (parameter is FieldFormalParameter) return parameter.type;
    if (parameter is SuperFormalParameter) return parameter.type;
    if (parameter is DefaultFormalParameter) {
      // Recurse into the nested parameter (e.g., inside `required String name`).
      return _getParameterTypeNode(parameter.parameter);
    }
    return null;
  }
}
