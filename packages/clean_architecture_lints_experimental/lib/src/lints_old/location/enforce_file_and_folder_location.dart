// lib/src/lints/location/enforce_file_and_folder_location.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:architecture_lints/src/models/configs/inheritances_config.dart';
import 'package:architecture_lints/src/models/configs/naming_conventions_config.dart';
import 'package:architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class EnforceFileAndFolderLocation extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_file_and_folder_location',
    problemMessage: 'A {0} was found in a "{1}" directory, but it belongs in a "{2}" directory.',
    correctionMessage: 'Move this file to the correct directory or rename the class.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final List<_ComponentPattern> _sortedPatterns;

  EnforceFileAndFolderLocation({
    required super.config,
    required super.layerResolver,
  }) : _sortedPatterns = _createSortedPatterns(config.namingConventions.rules),
        super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    if (_sortedPatterns.isEmpty) return;

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final filePath = resolver.source.fullName;
      final classElement = node.declaredFragment?.element;

      // 1. Actual Location
      final actualComponent = layerResolver.getComponent(filePath);
      if (actualComponent == ArchComponent.unknown) return;

      // 2. Check Inheritance (Structural Identity)
      // If the class physically implements/extends the contract required by the ACTUAL location,
      // we assume the location is correct and the name might just be weird.
      // This prevents flagging "UserDTO" (extends Entity) as a misplaced Entity when it is in Models.
      if (classElement != null && _satisfiesInheritanceRule(classElement, actualComponent)) {
        return;
      }

      // 3. Expected Location (Based on Name)
      final bestMatch = _getBestMatch(className);
      if (bestMatch == null) return;

      final expectedComponent = bestMatch.component;

      if (expectedComponent != actualComponent) {
        // Exception A: Ambiguity / Specificity
        final actualPattern = _sortedPatterns.firstWhereOrNull(
              (p) =>
          p.component == actualComponent &&
              NamingUtils.validateName(name: className, template: p.pattern),
        );

        if (actualPattern != null) {
          if (actualPattern.pattern.length >= bestMatch.pattern.length) return;
        }

        reporter.atToken(
          node.name,
          _code,
          arguments: [
            expectedComponent.label, // e.g. Entity (guessed from name)
            actualComponent.label,   // e.g. Model (actual folder)
            expectedComponent.label, // e.g. Entity directory
          ],
        );
      }
    });
  }

  bool _satisfiesInheritanceRule(ClassElement element, ArchComponent targetComponent) {
    final rule = config.inheritances.ruleFor(targetComponent);
    if (rule == null || rule.required.isEmpty) return false;

    return rule.required.any((detail) => _hasSupertype(element, detail));
  }

  bool _hasSupertype(ClassElement element, InheritanceDetail detail) {
    // Case 1: Component-based check (e.g. required: component: 'entity')
    if (detail.component != null) {
      final requiredComponent = ArchComponent.fromId(detail.component!);
      if (requiredComponent == ArchComponent.unknown) return false;

      return element.allSupertypes.any((supertype) {
        final source = supertype.element.library.firstFragment.source;
        // Resolve the component type of the superclass
        final superComp = layerResolver.getComponent(source.fullName);

        return superComp == requiredComponent;
      });
    }

    // Case 2: Explicit Name/Import check
    if (detail.name == null || detail.import == null) return false;

    return element.allSupertypes.any((supertype) {
      final superElement = supertype.element;
      if (superElement.name != detail.name) return false;

      final libraryUri = superElement.library.firstFragment.source.uri.toString();
      final configUri = detail.import!;

      if (libraryUri == configUri) return true;

      final libSuffix = _extractPathSuffix(libraryUri);
      final configSuffix = _extractPathSuffix(configUri);

      if (libSuffix != null && configSuffix != null && libSuffix == configSuffix) return true;

      if (libraryUri.endsWith(configUri)) return true;

      return false;
    });
  }

  String? _extractPathSuffix(String uriString) {
    final uri = Uri.tryParse(uriString);
    if (uri == null) return null;

    if (uri.scheme == 'package') {
      if (uri.pathSegments.length > 1) {
        return uri.pathSegments.sublist(1).join('/');
      }
    } else if (uri.scheme == 'file') {
      final segments = uri.pathSegments;
      final libIndex = segments.lastIndexOf('lib');
      if (libIndex != -1 && libIndex < segments.length - 1) {
        return segments.sublist(libIndex + 1).join('/');
      }
    }
    return uriString;
  }

  _ComponentPattern? _getBestMatch(String className) {
    return _sortedPatterns.firstWhereOrNull(
          (p) => NamingUtils.validateName(name: className, template: p.pattern),
    );
  }

  static List<_ComponentPattern> _createSortedPatterns(List<NamingRule> rules) {
    final patterns =
    rules
        .expand((rule) {
      return rule.on.map((componentId) {
        final component = ArchComponent.fromId(componentId);
        return component != ArchComponent.unknown
            ? _ComponentPattern(pattern: rule.pattern, component: component)
            : null;
      });
    })
        .whereNotNull()
        .toList()
      ..sort((a, b) => b.pattern.length.compareTo(a.pattern.length));
    return patterns;
  }
}

class _ComponentPattern {
  final String pattern;
  final ArchComponent component;
  const _ComponentPattern({required this.pattern, required this.component});
}