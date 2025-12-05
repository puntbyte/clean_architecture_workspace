import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/config/enums/relationship_element.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/relationship_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:architecture_lints/src/utils/naming_utils.dart';
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

mixin RelationshipLogic on InheritanceLogic {
  /// Extracts the core name (e.g. 'User') from a class name (e.g. 'UserEntity').
  String? extractCoreName(String className, ComponentConfig config) {
    if (config.patterns.isEmpty) return className;

    for (final pattern in config.patterns) {
      final regexStr = '^' +
          RegExp.escape(pattern)
              .replaceAll(RegExp.escape('{{name}}'), r'(.*)')
              .replaceAll(RegExp.escape('{{affix}}'), r'.*') +
          '\$';

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
        final moduleRoot =
        currentDir.substring(0, currentDir.length - relativeSuffix.length);

        if (targetComponent.paths.isNotEmpty) {
          final targetRelative =
          targetComponent.paths.first.replaceAll('/', p.separator);
          final targetDir = p.join(moduleRoot, targetRelative);
          return p.join(targetDir, targetFileName);
        }
      }
    }
    return null;
  }

  String toSnakeCase(String input) {
    return input.replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
            (Match m) => '${m[1]}_${m[2]}').toLowerCase();
  }

  /// Centralized logic to find what file is missing for a given node.
  /// Returns [ParityTarget] if a rule is violated and the file is missing.
  ParityTarget? findMissingTarget({
    required AstNode node,
    required ArchitectureConfig config,
    required ComponentConfig currentComponent,
    required FileResolver fileResolver,
    required String currentFilePath,
  }) {
    String? name;
    RelationshipElement? type;
    String? methodName;

    // 1. Extract Info based on Node Type
    if (node is ClassDeclaration) {
      name = node.name.lexeme;
      type = RelationshipElement.classElement;
    } else if (node is MethodDeclaration) {
      methodName = node.name.lexeme;
      // Capitalize method name for class generation (login -> Login)
      name = methodName[0].toUpperCase() + methodName.substring(1);
      type = RelationshipElement.methodElement;
    }

    if (name == null || type == null) return null;

    // 2. Find Applicable Rules
    final rules = config.relationships.where((rule) {
      return rule.element == type &&
          rule.onIds.any((id) => componentMatches(id, currentComponent.id));
    }).toList();

    for (final rule in rules) {
      // Check Visibility (Method specific)
      if (node is MethodDeclaration) {
        final element = node.declaredFragment?.element;
        if (element != null && rule.visibility == 'public' && element.isPrivate) {
          continue;
        }
      }

      // 3. Resolve Target Config
      ComponentConfig? targetComponent;
      try {
        targetComponent =
            config.components.firstWhere((c) => c.id == rule.targetComponent);
      } on StateError {
        continue;
      }

      // 4. Calculate Paths
      // For methods, the core name IS the name derived above.
      // For classes, we extract it.
      String? coreName = name;
      if (node is ClassDeclaration) {
        coreName = extractCoreName(name, currentComponent);
      }

      if (coreName == null) continue;

      final targetClassName = generateTargetClassName(coreName, targetComponent);
      final targetFileName = '${toSnakeCase(targetClassName)}.dart';

      final targetPath = findTargetFilePath(
        currentFilePath: currentFilePath,
        currentComponent: currentComponent,
        targetComponent: targetComponent,
        targetFileName: targetFileName,
      );

      if (targetPath != null) {
        // Return this target if we want to act on it.
        // The Rule checks !exists(), the Fix assumes it's needed.
        return ParityTarget(
          path: targetPath,
          coreName: coreName,
          targetClassName: targetClassName,
          templateId: rule.action,
          sourceComponent: currentComponent,
        );
      }
    }
    return null;
  }
}