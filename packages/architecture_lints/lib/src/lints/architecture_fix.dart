import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:architecture_lints/src/engines/configuration/configuration.dart';
import 'package:architecture_lints/src/engines/file/file.dart';
import 'package:architecture_lints/src/engines/generator/generator.dart';
import 'package:architecture_lints/src/engines/template/template.dart';
import 'package:architecture_lints/src/engines/variable/variable.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/action_definition.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/enums/write_placement.dart';
import 'package:architecture_lints/src/schema/enums/write_strategy.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

class ArchitectureFix extends DartFix {
  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    try {
      if (!context.sharedState.containsKey(ArchitectureConfig)) {
        final config = await ConfigLoader.loadFromContext(resolver.path);
        if (config != null) context.sharedState[ArchitectureConfig] = config;
      }
      if (!context.sharedState.containsKey(ResolvedUnitResult)) {
        final unit = await resolver.getResolvedUnitResult();
        context.sharedState[ResolvedUnitResult] = unit;
      }
    } catch (e) {}
    await super.startUp(resolver, context);
  }

  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
    List<Diagnostic> others,
  ) {
    try {
      protectedRun(resolver, reporter, context, analysisError);
    } catch (e, stack) {}
  }

  @visibleForTesting
  void protectedRun(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError,
  ) {
    final config = context.sharedState[ArchitectureConfig] as ArchitectureConfig?;
    final unitResult = context.sharedState[ResolvedUnitResult] as ResolvedUnitResult?;

    if (config == null) return;

    if (unitResult == null) return;

    final errorCode = analysisError.diagnosticCode.name;


    final actions = config.getActionsForError(errorCode);

    if (actions.isEmpty) return;

    final rootPath = ConfigLoader.findRootPath(resolver.path) ?? p.dirname(resolver.path);

    final loader = TemplateLoader(rootPath);
    final generator = CodeGenerator(config, loader, context.pubspec.name);
    const renderer = MustacheRenderer();

    var errorNode = _findNodeAt(unitResult.unit, analysisError.offset);
    // Find Declaration
    while (errorNode != null) {
      if (errorNode is MethodDeclaration || errorNode is ClassDeclaration) break;
      errorNode = errorNode.parent;
    }
    errorNode ??= unitResult.unit.declarations.firstOrNull ?? unitResult.unit;

    for (final action in actions) {
      _executeAction(
        action: action,
        sourceNode: errorNode,
        config: config,
        packageName: context.pubspec.name,
        resolver: resolver,
        unitResult: unitResult,
        reporter: reporter,
        generator: generator,
        renderer: renderer,
      );
    }
  }

  void _executeAction({
    required ActionDefinition action,
    required AstNode sourceNode,
    required ArchitectureConfig config,
    required String packageName,
    required CustomLintResolver resolver,
    required ResolvedUnitResult unitResult,
    required ChangeReporter reporter,
    required CodeGenerator generator,
    required MustacheRenderer renderer,
  }) {
    // A. Generate Code
    final code = generator.generate(action: action, sourceNode: sourceNode);

    if (code == null) return;

    // B. Calculate Target Path
    String? targetPath;
    if (action.write.filename != null && action.write.filename!.isNotEmpty) {
      targetPath = _resolveTargetPath(
        action: action,
        sourceNode: sourceNode,
        config: config,
        packageName: packageName,
        currentPath: resolver.path,
        renderer: renderer,
      );
    }

    // C. Apply Edit
    _applyEdit(
      reporter: reporter,
      action: action,
      code: code,
      targetPath: targetPath,
      currentPath: resolver.path,
      sourceNode: sourceNode,
      unitResult: unitResult,
    );
  }

  String? _resolveTargetPath({
    required ActionDefinition action,
    required AstNode sourceNode,
    required ArchitectureConfig config,
    required String packageName,
    required String currentPath,
    required MustacheRenderer renderer,
  }) {
    final variableResolver = VariableResolver(
      sourceNode: sourceNode,
      config: config,
      packageName: packageName,
    );

    final templateContext = variableResolver.resolveMap(action.variables);

    final filenamePattern = action.write.filename!;
    // Evaluate expressions in filename
    final resolvedFilename = filenamePattern.replaceAllMapped(RegExp(r'\$\{(.*?)\}'), (
      Match match,
    ) {
      final expr = match.group(1);
      final res = expr != null ? variableResolver.resolve(expr).toString() : match.group(0)!;
      return res;
    });

    final fileName = renderer.render(resolvedFilename, templateContext);

    final targetDir = _resolveSmartPath(
      currentPath: currentPath,
      targetComponentId: action.target.component,
      config: config,
    );

    if (targetDir == null) return null;
    return p.normalize(p.join(targetDir, fileName));
  }

  String? _resolveSmartPath({
    required String currentPath,
    required String? targetComponentId,
    required ArchitectureConfig config,
  }) {
    if (targetComponentId == null) return p.dirname(currentPath);

    final fileResolver = FileResolver(config);
    final currentContext = fileResolver.resolve(currentPath);

    if (currentContext == null) return p.dirname(currentPath);

    ComponentDefinition? targetConfig;
    try {
      targetConfig = config.components.firstWhere((c) => c.id == targetComponentId);
    } catch (_) {
      return p.dirname(currentPath);
    }

    final currentDir = p.dirname(currentPath);

    for (final path in currentContext.definition.paths) {
      final configPath = path.replaceAll('/', p.separator);
      if (currentDir.endsWith(configPath)) {
        final moduleRoot = currentDir.substring(0, currentDir.lastIndexOf(configPath));
        if (targetConfig.paths.isNotEmpty) {
          final targetRelative = targetConfig.paths.first.replaceAll('/', p.separator);
          return p.join(moduleRoot, targetRelative);
        }
      }
    }
    return currentDir;
  }

  void _applyEdit({
    required ChangeReporter reporter,
    required ActionDefinition action,
    required String code,
    required String? targetPath,
    required String currentPath,
    required AstNode sourceNode,
    required ResolvedUnitResult unitResult,
  }) {
    final changeBuilder =
        reporter.createChangeBuilder(
          message: action.description,
          priority: 100,
        )..addDartFileEdit((builder) {
          switch (action.write.strategy) {
            case WriteStrategy.file:
              _applyFileEdit(builder, code, targetPath, currentPath, unitResult);
            case WriteStrategy.inject:
              _applyInjectionEdit(builder, code, sourceNode, action.write.placement);
            case WriteStrategy.replace:
              builder.addReplacement(
                SourceRange(sourceNode.offset, sourceNode.length),
                (editBuilder) => editBuilder.write(code),
              );
          }
        }, customPath: targetPath);
  }

  void _applyFileEdit(
    DartFileEditBuilder builder,
    String code,
    String? targetPath,
    String currentPath,
    ResolvedUnitResult unitResult,
  ) {
    if (targetPath != null && targetPath != currentPath) {
      builder.addReplacement(SourceRange.EMPTY, (editBuilder) => editBuilder.write(code));
    } else {
      builder.addInsertion(unitResult.unit.end, (editBuilder) => editBuilder.write('\n$code'));
    }
  }

  void _applyInjectionEdit(
    DartFileEditBuilder builder,
    String code,
    AstNode sourceNode,
    WritePlacement placement,
  ) {
    final classNode = sourceNode.thisOrAncestorOfType<ClassDeclaration>();

    int offset;
    if (classNode != null) {
      if (placement == WritePlacement.end) {
        offset = classNode.rightBracket.offset;
      } else {
        offset = classNode.leftBracket.end;
      }
    } else {
      offset = sourceNode.end;
    }

    builder.addInsertion(offset, (editBuilder) => editBuilder.write('\n$code'));
  }

  AstNode? _findNodeAt(CompilationUnit unit, int offset) {
    var currentNode = unit as AstNode;
    while (true) {
      AstNode? childFound;
      for (final child in currentNode.childEntities) {
        if (child is AstNode) {
          if (child.offset <= offset && child.end >= offset) {
            childFound = child;
            break;
          }
        }
      }
      if (childFound != null) {
        currentNode = childFound;
      } else {
        return currentNode;
      }
    }
  }
}
