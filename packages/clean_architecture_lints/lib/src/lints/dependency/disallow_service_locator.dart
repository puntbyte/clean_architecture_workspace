// lib/src/lints/dependency/disallow_service_locator.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// A lint that forbids the use of the Service Locator pattern.
class DisallowServiceLocator extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'disallow_service_locator',
    problemMessage:
    'Do not use a service locator. Dependencies should be explicit and injected via the '
        'constructor.',
    correctionMessage: 'Add this dependency as a constructor parameter.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const DisallowServiceLocator({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component == ArchComponent.unknown) return;

    final rule = config.services.serviceLocator;
    final locatorNames = rule.names.toSet();
    final locatorImport = rule.import;

    if (locatorNames.isEmpty && locatorImport == null) return;

    context.registry.addSimpleIdentifier((node) {
      // Ignore declarations (we only want usages)
      if (node.inDeclarationContext()) return;

      // Ignore parameter labels
      if (node.parent is Label) return;

      // 1. Check Name (Fast)
      if (locatorNames.contains(node.name)) {
        reporter.atNode(node, _code);
        return;
      }

      // 2. Check Import / Source Library (Robust)
      if (locatorImport != null) {
        final element = node.staticType?.element;
        if (element == null) return;

        // [Analyzer 8.0.0] Use firstFragment.source
        final library = element.library;
        if (library == null) return;

        final sourceUri = library.firstFragment.source.uri.toString();

        if (_matchesImport(sourceUri, locatorImport)) {
          reporter.atNode(node, _code);
        }
      }
    });
  }

  bool _matchesImport(String actualUriString, String configUriString) {
    // 1. Exact Match
    if (actualUriString == configUriString) return true;

    // 2. Suffix Match (Robust for tests/templates)
    // Extracts 'path/to/file.dart' from 'package:pkg/path/to/file.dart' or 'file:///.../path/to/file.dart'
    final actualSuffix = _extractPathSuffix(actualUriString);
    final configSuffix = _extractPathSuffix(configUriString);

    if (actualSuffix != null && configSuffix != null) {
      return actualSuffix == configSuffix;
    }

    // 3. Fallback EndsWith
    return actualUriString.endsWith(configUriString);
  }

  String? _extractPathSuffix(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;

    if (uri.scheme == 'package') {
      // package:get_it/get_it.dart -> get_it.dart
      // package:example/core/utils.dart -> core/utils.dart
      if (uri.pathSegments.length > 1) {
        return uri.pathSegments.sublist(1).join('/');
      }
    } else if (uri.scheme == 'file') {
      // file:///.../lib/get_it.dart -> get_it.dart
      final segments = uri.pathSegments;
      final libIndex = segments.lastIndexOf('lib');
      if (libIndex != -1 && libIndex < segments.length - 1) {
        return segments.sublist(libIndex + 1).join('/');
      }
    }
    return uriString;
  }
}