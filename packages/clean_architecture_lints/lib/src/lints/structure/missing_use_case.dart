// lib/src/lints/structure/missing_use_case.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart'; // Import Analyzer FileSystem
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/fixes/create_use_case_fix.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/file/path_utils.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MissingUseCase extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'missing_use_case',
    problemMessage: 'The repository method `{0}` is missing the corresponding `{1}` UseCase.',
    correctionMessage: 'Press 💡 to generate the UseCase file automatically.',
  );

  const MissingUseCase({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  @override
  List<Fix> getFixes() => [CreateUseCaseFix(config: config)];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.port) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword == null) return;

      // Get the ResourceProvider from the analyzer session.
      // This ensures we see the same file system (including memory overlays) as the analyzer.
      final element = node.declaredFragment?.element;
      final resourceProvider = element?.session?.resourceProvider;

      if (resourceProvider == null) return;

      for (final member in node.members) {
        if (member is MethodDeclaration &&
            !member.isGetter &&
            !member.isSetter &&
            !member.name.lexeme.startsWith('_')) {
          _checkMethod(
            method: member,
            repoPath: resolver.source.fullName,
            reporter: reporter,
            resourceProvider: resourceProvider,
          );
        }
      }
    });
  }

  void _checkMethod({
    required MethodDeclaration method,
    required String repoPath,
    required DiagnosticReporter reporter,
    required ResourceProvider resourceProvider,
  }) {
    final methodName = method.name.lexeme;

    // Pass the resourceProvider to PathUtils to ensure correct root resolution
    final expectedFilePath = PathUtils.getUseCaseFilePath(
      methodName: methodName,
      repoPath: repoPath,
      config: config,
      resourceProvider: resourceProvider,
    );

    if (expectedFilePath == null) return;

    // Use the provider to check for existence.
    // This works for physical files AND in-memory test files.
    final file = resourceProvider.getFile(expectedFilePath);

    if (!file.exists) {
      final expectedClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);
      reporter.atToken(
        method.name,
        _code,
        arguments: [methodName, expectedClassName],
      );
    }
  }
}
