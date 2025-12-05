import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/config/enums/relationship_element.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/domain/component_context.dart';
import 'package:path/path.dart' as p;

class ParityTarget {
  final String path;
  final String coreName;
  final String targetClassName;
  final String? templateId;
  final ComponentConfig sourceComponent;

  ParityTarget({
    required this.path,
    required this.coreName,
    required this.targetClassName,
    required this.templateId,
    required this.sourceComponent,
  });
}

mixin RelationshipLogic {
  // Uses context's config for patterns
  String? extractCoreName(String className, ComponentContext context) {
    if (context.patterns.isEmpty) return className;

    for (final pattern in context.patterns) {
      final regexStr =
          '^${RegExp.escape(pattern).replaceAll(RegExp.escape('{{name}}'), '(.*)').replaceAll(RegExp.escape('{{affix}}'), '.*')}\$';

      final match = RegExp(regexStr).firstMatch(className);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  String generateTargetClassName(String coreName, ComponentConfig targetConfig) {
    if (targetConfig.patterns.isEmpty) return coreName;
    final pattern = targetConfig.patterns.first;
    return pattern.replaceAll('{{name}}', coreName).replaceAll('{{affix}}', '');
  }

  String? findTargetFilePath({
    required String currentFilePath,
    required ComponentConfig currentComponent,
    required ComponentConfig targetComponent,
    required String targetFileName,
  }) {
    final currentDir = p.dirname(currentFilePath);

    for (final path in currentComponent.paths) {
      final relativeSuffix = path.replaceAll('/', p.separator);

      if (currentDir.endsWith(relativeSuffix)) {
        final moduleRoot = currentDir.substring(0, currentDir.length - relativeSuffix.length);

        if (targetComponent.paths.isNotEmpty) {
          final targetRelative = targetComponent.paths.first.replaceAll('/', p.separator);
          final targetDir = p.join(moduleRoot, targetRelative);
          return p.join(targetDir, targetFileName);
        }
      }
    }
    return null;
  }

  String toSnakeCase(String input) {
    return input
        .replaceAllMapped(RegExp('([a-z])([A-Z])'), (Match m) => '${m[1]}_${m[2]}')
        .toLowerCase();
  }

  ParityTarget? findMissingTarget({
    required AstNode node,
    required ArchitectureConfig config,
    required ComponentContext currentComponent,
    required FileResolver fileResolver,
    required String currentFilePath,
  }) {
    String? name;
    RelationshipElement? type;
    String? methodName;

    if (node is ClassDeclaration) {
      name = node.name.lexeme;
      type = RelationshipElement.classElement;
    } else if (node is MethodDeclaration) {
      methodName = node.name.lexeme;
      name = methodName[0].toUpperCase() + methodName.substring(1);
      type = RelationshipElement.methodElement;
    }

    if (name == null || type == null) return null;

    // Filter rules using Context matching
    final rules = config.relationships.where((rule) {
      return rule.element == type && currentComponent.matchesAny(rule.onIds);
    }).toList();

    for (final rule in rules) {
      if (node is MethodDeclaration) {
        final element = node.declaredFragment?.element;
        if (element != null && rule.visibility == 'public' && element.isPrivate) {
          continue;
        }
      }

      ComponentConfig? targetComponent;
      try {
        targetComponent = config.components.firstWhere((c) => c.id == rule.targetComponent);
      } catch (e) {
        continue;
      }

      String? coreName = name;
      if (node is ClassDeclaration) {
        coreName = extractCoreName(name, currentComponent);
      }

      if (coreName == null) continue;

      final targetClassName = generateTargetClassName(coreName, targetComponent);
      final targetFileName = '${toSnakeCase(targetClassName)}.dart';

      final targetPath = findTargetFilePath(
        currentFilePath: currentFilePath,
        currentComponent: currentComponent.config, // Need Config for paths
        targetComponent: targetComponent,
        targetFileName: targetFileName,
      );

      if (targetPath != null) {
        return ParityTarget(
          path: targetPath,
          coreName: coreName,
          targetClassName: targetClassName,
          templateId: rule.action,
          sourceComponent: currentComponent.config,
        );
      }
    }
    return null;
  }
}
