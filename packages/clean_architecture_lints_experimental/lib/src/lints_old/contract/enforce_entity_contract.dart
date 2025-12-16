// lib/src/lints/contract/enforce_entity_contract.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:architecture_lints/src/models/configs/inheritances_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceEntityContract extends ArchitectureRule {
  static const _code = LintCode(
    name: 'enforce_entity_contract',
    problemMessage: 'Entities must extend or implement: {0}.',
    correctionMessage: 'Add `extends {0}` to the class definition.',
  );

  static const _defaultRule = InheritanceDetail(
    name: 'Entity',
    import: 'package:clean_architecture_core/clean_architecture_core.dart',
  );

  const EnforceEntityContract({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    if (layerResolver.getComponent(resolver.source.fullName) != ArchComponent.entity) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword != null) return;

      final element = node.declaredFragment?.element;
      if (element == null) return;

      final customRule = definition.inheritances.ruleFor(ArchComponent.entity);
      final requiredSupertypes = customRule?.required.isNotEmpty ?? false
          ? customRule!.required
          : [
              _defaultRule,
              InheritanceDetail(
                name: 'Entity',
                import: 'package:${context.pubspec.name}/core/entity/entity.dart',
              ),
            ];

      final hasCorrectSupertype = requiredSupertypes.any(
        (detail) => _hasSupertype(element, detail),
      );

      if (!hasCorrectSupertype) {
        final requiredNames = requiredSupertypes
            .map((r) => r.name)
            .where((n) => n != null)
            .toSet()
            .join(' or ');

        reporter.atToken(
          node.name,
          _code,
          arguments: [requiredNames],
        );
      }
    });
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail) {
    if (detail.name == null || detail.import == null) return false;

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;

      if (superElement.name != detail.name) return false;

      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      final configUri = detail.import!;

      // 1. Exact Match
      if (libraryUri == configUri) return true;

      // 2. Suffix Match (Handles file:// vs package: difference in tests)
      final libSuffix = _extractPathSuffix(libraryUri);
      final configSuffix = _extractPathSuffix(configUri);

      if (libSuffix != null && configSuffix != null && libSuffix == configSuffix) {
        return true;
      }

      return libraryUri.endsWith(configUri);
    });
  }

  String? _extractPathSuffix(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;

    if (uri.scheme == 'package') {
      // package:example/core/entity.dart -> core/entity.dart
      if (uri.pathSegments.length > 1) {
        return uri.pathSegments.sublist(1).join('/');
      }
    } else if (uri.scheme == 'file') {
      // file:///.../lib/core/entity.dart -> core/entity.dart
      final segments = uri.pathSegments;
      final libIndex = segments.lastIndexOf('lib');
      if (libIndex != -1 && libIndex < segments.length - 1) {
        return segments.sublist(libIndex + 1).join('/');
      }
    }
    return uriString;
  }
}
