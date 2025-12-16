// lib/src/lints/consistency/logic/relationship_logic.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:architecture_lints/src/schema/enums/relationship_kind.dart';
import 'package:architecture_lints/src/schema/enums/relationship_visibility.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:path/path.dart' as p;

mixin RelationshipLogic on NamingLogic {
  String? extractCoreName(String className, ComponentContext context) {
    if (context.patterns.isEmpty) return className;

    for (final pattern in context.patterns) {
      final coreName = extractCoreNameFromPattern(className, pattern);
      if (coreName != null) return coreName;
    }

    return null;
  }

  String generateTargetClassName(String coreName, ComponentDefinition targetConfig) {
    if (targetConfig.patterns.isEmpty) return coreName;
    final pattern = targetConfig.patterns.first;
    return pattern
        .replaceAll(ConfigKeys.placeholder.name, coreName)
        .replaceAll(ConfigKeys.placeholder.affix, '');
  }

  String toSnakeCase(String input) => input
      .replaceAllMapped(RegExp('([a-z])([A-Z])'), (Match match) => '${match[1]}_${match[2]}')
      .toLowerCase();

  ParityResult findMissingTarget({
    required AstNode node,
    required ArchitectureConfig config,
    required ComponentContext currentComponent,
    required FileResolver fileResolver,
    required String currentFilePath,
  }) {
    String? name;
    RelationshipKind? kind;
    String? methodName;

    if (node is ClassDeclaration) {
      name = node.name.lexeme;
      kind = RelationshipKind.class$;
    } else if (node is MethodDeclaration) {
      methodName = node.name.lexeme;
      name = methodName.isEmpty ? '' : '${methodName[0].toUpperCase()}${methodName.substring(1)}';
      kind = RelationshipKind.method;
    }

    if (name == null || kind == null) {
      return const ParityResult.failure('Node is not a Class or Method');
    }

    final rules = config.relationships.where((rule) {
      if (rule.kind != kind) return false;

      if (node is MethodDeclaration) {
        final element = node.declaredFragment?.element;
        if (element != null &&
            rule.visibility == RelationshipVisibility.public &&
            element.isPrivate) {
          return false;
        }
      }

      return currentComponent.matchesAny(rule.onIds);
    }).toList();

    if (rules.isEmpty) return const ParityResult.failure('No matching rules found');

    for (final rule in rules) {
      ComponentDefinition? targetComponent;
      try {
        targetComponent = config.components.firstWhere(
          (component) => component.id == rule.targetComponent,
        );
      } catch (e) {
        continue;
      }

      String? coreName = name;
      if (node is ClassDeclaration) coreName = extractCoreName(name, currentComponent);

      if (coreName == null) continue;

      final targetClassName = generateTargetClassName(coreName, targetComponent);
      final targetFileName = '${toSnakeCase(targetClassName)}.dart';

      final targetPath = findTargetFilePath(
        currentFilePath: currentFilePath,
        currentComponent: currentComponent.definition,
        targetComponent: targetComponent,
        targetFileName: targetFileName,
      );

      if (targetPath != null) {
        return ParityResult.success(
          ParityTarget(
            path: targetPath,
            coreName: coreName,
            targetClassName: targetClassName,
            templateId: rule.action,
            sourceComponent: currentComponent.definition,
          ),
        );
      }
    }

    return const ParityResult.failure('Path resolution failed for all rules');
  }

  String? findTargetFilePath({
    required String currentFilePath,
    required ComponentDefinition currentComponent,
    required ComponentDefinition targetComponent,
    required String targetFileName,
  }) {
    final currentDir = p.dirname(currentFilePath);

    for (final path in currentComponent.paths) {
      final configPath = path.replaceAll('/', p.separator);

      if (currentDir.endsWith(configPath) || currentDir.endsWith(p.separator + configPath)) {
        final moduleRoot = currentDir.substring(0, currentDir.lastIndexOf(configPath));
        if (targetComponent.paths.isNotEmpty) {
          final targetRelative = targetComponent.paths.first.replaceAll('/', p.separator);
          final targetDir = p.join(moduleRoot, targetRelative);
          return p.normalize(p.join(targetDir, targetFileName));
        }
      }
    }

    return null;
  }
}

class ParityTarget {
  final String path;
  final String coreName;
  final String targetClassName;
  final String? templateId;
  final ComponentDefinition sourceComponent;

  const ParityTarget({
    required this.path,
    required this.coreName,
    required this.targetClassName,
    required this.templateId,
    required this.sourceComponent,
  });
}

class ParityResult {
  final ParityTarget? target;
  final String? failureReason;

  const ParityResult.success(this.target) : failureReason = null;
  const ParityResult.failure(this.failureReason) : target = null;
}
