import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint rule that flags any direct import of a Flutter package
/// inside a file belonging to the domain layer.
class DisallowFlutterImportsInDomain extends DartLintRule {
  static const _code = LintCode(
    name: 'disallow_flutter_imports_in_domain',
    problemMessage: 'Do not import Flutter packages in the domain layer.',
    correctionMessage: 'The domain layer must be platform-independent. Remove this import.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const DisallowFlutterImportsInDomain({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // Determine the layer of the current file.
    final layer = layerResolver.getLayer(resolver.source.fullName);
    // Only run this lint on files within the domain layer.
    if (layer != ArchLayer.domain) return;

    // Register a visitor to inspect every import directive in the file.
    context.registry.addImportDirective((node) {
      final importUri = node.uri.stringValue;
      if (importUri != null && importUri.startsWith('package:flutter/')) {
        // If the import URI starts with 'package:flutter/', report an error.
        reporter.atNode(node, _code);
      }
    });
  }
}
