import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/core/generation/template_engine.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/consistency/logic/relationship_logic.dart';
import 'package:architecture_lints/src/lints/identity/logic/inheritance_logic.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class CreateMissingComponentFix extends DartFix with InheritanceLogic, RelationshipLogic {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic analysisError, // Fix: Use Diagnostic instead of AnalysisError
    List<Diagnostic> others, // Fix: Use Diagnostic list
  ) {
    final config = context.sharedState[ArchitectureConfig] as ArchitectureConfig?;
    final fileResolver = context.sharedState[FileResolver] as FileResolver?;
    if (config == null || fileResolver == null) return;

    resolver.getResolvedUnitResult().then((unit) {
      // FIX: Use a manual loop to find the node safely.
      // firstWhere throwing or returning CompilationUnit was the issue.
      AstNode? node;
      for (final declaration in unit.unit.declarations) {
        if (declaration.offset <= analysisError.offset &&
            declaration.end >= analysisError.offset + analysisError.length) {
          node = declaration;
          break;
        }
      }

      if (node == null) return;

      final component = fileResolver.resolve(resolver.path);
      if (component == null) return;

      final target = findMissingTarget(
        node: node,
        config: config,
        currentComponent: component,
        fileResolver: fileResolver,
        currentFilePath: resolver.path,
      );

      if (target == null || target.templateId == null) return;

      final template = config.templates[target.templateId];
      if (template == null) return;

      final content = TemplateEngine.render(template, target.coreName);

      reporter
          .createChangeBuilder(
            message: 'Create missing file: ${target.targetClassName}',
            priority: 100,
          )
          .addGenericFileEdit((builder) {
            builder.addSimpleInsertion(0, content);
          }, customPath: target.path);
    });
  }
}
