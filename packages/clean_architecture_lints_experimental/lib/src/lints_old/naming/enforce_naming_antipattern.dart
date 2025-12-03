// lib/src/lints/naming/enforce_naming_antipattern.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/models/configs/inheritances_config.dart';
import 'package:architecture_lints/src/utils/nlp/naming_strategy.dart';
import 'package:architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceNamingAntipattern extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_naming_antipattern',
    problemMessage: 'The name `{0}` uses a forbidden pattern for a {1}.',
    correctionMessage: 'Rename the class to avoid the forbidden pattern.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final NamingStrategy _namingStrategy;

  EnforceNamingAntipattern({
    required super.config,
    required super.layerResolver,
  }) : _namingStrategy = NamingStrategy(config.namingConventions.rules),
       super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;

      final actualComponent = layerResolver.getComponent(filePath, className: className);
      if (actualComponent == ArchComponent.unknown) return;

      final rule = config.namingConventions.ruleFor(actualComponent);
      if (rule == null || rule.antipattern == null || rule.antipattern!.isEmpty) return;

      final element = node.declaredFragment?.element;
      final isInheritanceValid =
          element != null && _satisfiesInheritanceRule(element, actualComponent);

      if (_namingStrategy.shouldYieldToLocationLint(
        className,
        actualComponent,
        isInheritanceValid,
      )) {
        return;
      }

      if (NamingUtils.validateName(name: className, template: rule.antipattern!)) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [className, actualComponent.label],
        );
      }
    });
  }

  // --- Inheritance Check Logic ---
  bool _satisfiesInheritanceRule(ClassElement element, ArchComponent targetComponent) {
    final rule = config.inheritances.ruleFor(targetComponent);
    if (rule == null || rule.required.isEmpty) return false;
    return rule.required.any((detail) => _hasSupertype(element, detail));
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail) {
    if (detail.component != null) {
      final requiredComponent = ArchComponent.fromId(detail.component!);
      if (requiredComponent == ArchComponent.unknown) return false;
      return element.allSupertypes.any((supertype) {
        final source = supertype.element.library.firstFragment.source;
        return layerResolver.getComponent(source.fullName) == requiredComponent;
      });
    }
    if (detail.name == null || detail.import == null) return false;
    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      if (superElement.name != detail.name) return false;
      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      final configUri = detail.import!;
      if (libraryUri == configUri || libraryUri.endsWith(configUri)) return true;
      if (_extractPathSuffix(libraryUri) == _extractPathSuffix(configUri)) return true;
      return false;
    });
  }

  String? _extractPathSuffix(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;
    if (uri.scheme == 'package' && uri.pathSegments.length > 1) {
      return uri.pathSegments.sublist(1).join('/');
    }
    if (uri.scheme == 'file') {
      final segments = uri.pathSegments;
      final libIndex = segments.lastIndexOf('lib');
      if (libIndex != -1 && libIndex < segments.length - 1) {
        return segments.sublist(libIndex + 1).join('/');
      }
    }
    return uriString;
  }
}
