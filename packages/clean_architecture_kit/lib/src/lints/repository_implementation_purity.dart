// lib/src/lints/repository_implementation_purity.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class RepositoryImplementationPurity extends DartLintRule {
  static const _code = LintCode(
    name: 'repository_implementation_purity',
    problemMessage:
        'Repository implementation purity violation: Overridden methods must return '
        'domain Entities, not Models.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const RepositoryImplementationPurity({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.dataRepository) return;

    context.registry.addMethodDeclaration((node) {
      final isPrivate = node.name.lexeme.startsWith('_');

      final isOverride = node.metadata.any(
        (annotation) =>
            annotation.name is SimpleIdentifier &&
            (annotation.name as SimpleIdentifier).name == 'override' &&
            annotation.atSign.type == TokenType.AT,
      );

      if (isPrivate || !isOverride) return;

      final returnType = node.returnType?.type;
      if (returnType == null) return;

      final successType = _extractSuccessType(returnType);
      if (successType == null) return;

      var successTypeName = successType.getDisplayString();
      if (successTypeName.endsWith('?')) {
        successTypeName = successTypeName.substring(0, successTypeName.length - 1);
      }

      if (NamingUtils.validateName(name: successTypeName, template: config.naming.model)) {
        reporter.reportError(
          Diagnostic.forValues(
            source: resolver.source,
            offset: node.returnType!.offset,
            length: node.returnType!.length,
            diagnosticCode: _code,
            message: _code.problemMessage,
            correctionMessage:
                'This method must return a pure Entity, but it returns the Model '
                '`$successTypeName`. You need to map the Model to an Entity before returning.',
          ),
        );
      }
    });
  }

  DartType? _extractSuccessType(DartType type) {
    if (type is! InterfaceType) return null;

    if (type.isDartAsyncFuture || type.isDartAsyncFutureOr) {
      if (type.typeArguments.isEmpty) return null;

      return _extractSuccessType(type.typeArguments.first);
    }

    if (type.element.name == 'Either' && type.typeArguments.length == 2) {
      return type.typeArguments[1];
    }

    return type;
  }
}
