// lib/src/engines/file/related_file_resolver.dart

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/consistency/logic/relationship_logic.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:path/path.dart' as p;

class RelatedFileResolver22 with NamingLogic, RelationshipLogic {
  final ArchitectureConfig config;

  const RelatedFileResolver22(this.config);

  /// Finds and resolves the AST of a related file.
  Future<ResolvedUnitResult?> resolveRelated({
    required ComponentContext currentContext,
    required String targetComponentId,
    required AnalysisSession session,
  }) async {
    // 1. Find Target Component Config
    ComponentDefinition? targetConfig;
    try {
      targetConfig = config.components.firstWhere((c) => c.id == targetComponentId);
    } catch (_) {
      return null;
    }

    // 2. Extract Core Name (e.g. UserModel -> User)
    final className = p.basenameWithoutExtension(currentContext.filePath).toPascalCase();
    final coreName = extractCoreName(className, currentContext);
    if (coreName == null) return null;

    // 3. Generate Target Info
    final targetClassName = generateTargetClassName(coreName, targetConfig);
    final targetFileName = '${toSnakeCase(targetClassName)}.dart';

    // 4. Calculate Path
    final targetPath = findTargetFilePath(
      currentFilePath: currentContext.filePath,
      currentComponent: currentContext.definition,
      targetComponent: targetConfig,
      targetFileName: targetFileName,
    );

    if (targetPath == null) return null;

    // 5. Resolve AST using the Session
    try {
      final result = await session.getResolvedUnit(targetPath);

      if (result is ResolvedUnitResult) {
        // CRITICAL FIX: Check if the file actually exists.
        // The analyzer might return a result for a non-existent path.
        if (!result.exists) return null;

        return result;
      }
    } catch (e) {
      return null;
    }

    return null;
  }
}

extension _StringExt on String {
  String toPascalCase() {
    if (isEmpty) return this;
    return split(
      '_',
    ).map((s) => s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '').join();
  }
}
