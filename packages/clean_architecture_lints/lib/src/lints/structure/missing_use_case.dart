// lib/src/lints/structure/missing_use_case.dart

import 'dart:io'; // For File check (sync)
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
// import 'package:clean_architecture_lints/src/fixes/create_use_case_fix.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/file/path_utils.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MissingUseCase extends ArchitectureLintRule {
  static const _code = LintCode(
    name: 'missing_use_case',
    problemMessage: 'The repository method `{0}` is missing the corresponding `{1}` UseCase.',
    correctionMessage: 'Create the UseCase file to handle this method.',
  );

  const MissingUseCase({
    required super.config,
    required super.layerResolver,
  }) : super(code: _code);

  // Uncomment when Fix is available
  // @override
  // List<Fix> getFixes() => [CreateUseCaseFix(config: config)];

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // Only run on Ports (Repository Interfaces)
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.port) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword == null) return;

      for (final member in node.members) {
        if (member is MethodDeclaration &&
            !member.isGetter &&
            !member.isSetter &&
            !member.name.lexeme.startsWith('_')) {

          _checkMethod(
            method: member,
            repoPath: resolver.source.fullName,
            reporter: reporter,
          );
        }
      }
    });
  }

  void _checkMethod({
    required MethodDeclaration method,
    required String repoPath,
    required DiagnosticReporter reporter,
  }) {
    final methodName = method.name.lexeme;

    // Calculate where the UseCase file SHOULD be.
    final expectedFilePath = PathUtils.getUseCaseFilePath(
      methodName: methodName,
      repoPath: repoPath,
      config: config,
    );

    if (expectedFilePath == null) return;

    // Check if the file exists.
    // Note: direct File I/O is acceptable here because we need to check strict existence
    // on the disk. The analyzer's resource provider is abstracted, but custom_lint
    // runs in a real Dart VM process where File() works.
    // For tests using MemoryResourceProvider, this requires the test to actually write files
    // or mock the PathUtils behavior (which is static, so hard to mock).
    // Instead, we rely on the fact that integration tests run on a real file system (temp dir).
    final fileExists = File(expectedFilePath).existsSync();

    if (!fileExists) {
      final expectedClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);
      reporter.atToken(
        method.name,
        _code,
        arguments: [methodName, expectedClassName],
      );
    }
  }
}