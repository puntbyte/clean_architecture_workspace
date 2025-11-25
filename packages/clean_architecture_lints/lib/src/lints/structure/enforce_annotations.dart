// lib/src/lints/structure/enforce_annotations.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/models/configs/annotations_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes have required annotations or do not have forbidden annotations.
class EnforceAnnotations extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_annotations',
    problemMessage: '{0}',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  const EnforceAnnotations({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component == ArchComponent.unknown) return;

    final rule = config.annotations.ruleFor(component.id);
    if (rule == null) return;

    // 1. Check Imports (Flag forbidden packages)
    context.registry.addImportDirective((node) {
      final uriString = node.uri.stringValue;
      if (uriString == null) return;

      for (final forbidden in rule.forbidden) {
        if (forbidden.import != null && _matchesImport(uriString, forbidden.import!)) {
          reporter.atNode(
            node,
            _code,
            arguments: [
              'The import `$uriString` is forbidden because it contains the `@${forbidden.name}` annotation.',
            ],
          );

          return;
        }
      }
    });

    // 2. Check Declarations (Forbidden & Required usage)
    context.registry.addAnnotatedNode((node) {
      // Filter: We only care about Type definitions (Class, Mixin, Enum)
      if (node is! NamedCompilationUnitMember) return;
      if (node is! ClassDeclaration && node is! MixinDeclaration && node is! EnumDeclaration) {
        return;
      }

      // A. Check Forbidden (Iterate annotations)
      final declaredAnnotations = <_ResolvedAnnotation>[];

      for (final annotation in node.metadata) {
        final resolved = _resolveAnnotation(annotation);
        if (resolved == null) continue;
        declaredAnnotations.add(resolved);

        for (final forbidden in rule.forbidden) {
          if (forbidden.name == resolved.name) {
            // Check import if configured
            if (forbidden.import != null && resolved.sourceUri != null) {
              if (!_matchesImport(resolved.sourceUri!, forbidden.import!)) continue;
            }

            // Report on the annotation itself
            reporter.atNode(
              annotation,
              _code,
              arguments: [
                'This ${component.label} must not have the `@${forbidden.name}` annotation.',
              ],
            );
          }
        }
      }

      // B. Check Required (Check list)
      for (final required in rule.required) {
        if (!_hasAnnotation(declaredAnnotations, required)) {
          reporter.atToken(
            node.name,
            _code,
            arguments: [
              'This ${component.label} is missing the required `@${required.name}` annotation.',
            ],
          );
        }
      }
    });
  }

  _ResolvedAnnotation? _resolveAnnotation(Annotation node) {
    // Handle Simple (@Injectable) vs Prefixed (@inject.Injectable)
    String? name;
    final id = node.name;
    if (id is SimpleIdentifier) {
      name = id.name;
    } else if (id is PrefixedIdentifier) {
      name = id.identifier.name;
    }

    if (name == null) return null;

    // Resolve Source URI
    final element = node.element ?? node.elementAnnotation?.element;
    final sourceUri = element?.library?.firstFragment.source.uri.toString();

    return _ResolvedAnnotation(name, sourceUri);
  }

  bool _hasAnnotation(List<_ResolvedAnnotation> declared, AnnotationDetail target) {
    return declared.any((declaredAnnotation) {
      if (declaredAnnotation.name != target.name) return false;
      if (target.import != null && declaredAnnotation.sourceUri != null) {
        return _matchesImport(declaredAnnotation.sourceUri!, target.import!);
      }
      return true;
    });
  }

  bool _matchesImport(String actual, String expected) {
    if (actual == expected) return true;
    if (actual.startsWith(expected)) return true;
    if (expected.startsWith('package:') && actual.endsWith(expected.split('/').last)) return true;
    return false;
  }
}

class _ResolvedAnnotation {
  final String name;
  final String? sourceUri;

  _ResolvedAnnotation(this.name, this.sourceUri);
}
