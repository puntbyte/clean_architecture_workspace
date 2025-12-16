// lib/src/lints/contract/enforce_port_contract.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/models/configs/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that Port interfaces (abstract classes in the Domain layer)
/// extend or implement the configured base class.
class EnforcePortContract extends ArchitectureRule {
  static const _code = LintCode(
    name: 'enforce_port_contract',
    problemMessage: 'Port interfaces must extend or implement: {0}.',
    correctionMessage: 'Add `implements {0}` or `extends {0}` to the class definition.',
  );

  static const _defaultRule = InheritanceDetail(
    name: 'Port',
    import: 'package:clean_architecture_core/clean_architecture_core.dart',
  );

  const EnforcePortContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.port) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword == null) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;

      // 1. Determine Rules (Custom > Default)
      final customRule = definition.inheritances.ruleFor(ArchComponent.port);
      final requiredSupertypes = customRule?.required.isNotEmpty ?? false
          ? customRule!.required
          : [
              _defaultRule,
              InheritanceDetail(
                name: 'Port',
                import: 'package:${context.pubspec.name}/core/port/port.dart',
              ),
            ];

      // 2. Check Inheritance
      final hasCorrectSupertype = requiredSupertypes.any(
        (detail) => _hasSupertype(element, detail),
      );

      if (!hasCorrectSupertype) {
        final requiredNames = requiredSupertypes
            .map((r) => r.name)
            .where((n) => n != null)
            .toSet()
            .join(' or ');

        reporter.atToken(node.name, _code, arguments: [requiredNames]);
      }
    });
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail) {
    if (detail.name == null || detail.import == null) return false;

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;

      // 1. Name Check
      if (superElement.name != detail.name) return false;

      // 2. URI Check
      // [Analyzer 8.0.0] Use firstFragment.source
      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      final configUri = detail.import!;

      // A. Exact Match
      if (libraryUri == configUri) return true;

      // B. Suffix Match (Handles test file:// vs config package:)
      final libSuffix = _extractPathSuffix(libraryUri);
      final configSuffix = _extractPathSuffix(configUri);

      if (libSuffix != null && configSuffix != null && libSuffix == configSuffix) return true;

      // C. Fallback
      if (libraryUri.endsWith(configUri)) return true;

      return false;
    });
  }

  String? _extractPathSuffix(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;

    if (uri.scheme == 'package') {
      if (uri.pathSegments.length > 1) return uri.pathSegments.sublist(1).join('/');
    } else if (uri.scheme == 'file') {
      final segments = uri.pathSegments;
      final libIndex = segments.lastIndexOf('lib');
      if (libIndex != -1 && libIndex < segments.length - 1) {
        return segments.sublist(libIndex + 1).join('/');
      }
    }

    return uriString;
  }
}
