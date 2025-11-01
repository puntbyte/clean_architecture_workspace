// lib/src/lints/missing_use_case.dart

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/fixes/create_use_case_fix.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:clean_architecture_kit/src/utils/path_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MissingUseCase extends DartLintRule {
  static const _code = LintCode(
    name: 'missing_use_case',
    problemMessage: 'Repository method `{0}` is missing a corresponding UseCase file.',
    correctionMessage: 'Consider creating a UseCase for this business logic.',
  );

  final CleanArchitectureConfig config;
  final LayerResolver layerResolver;

  const MissingUseCase({
    required this.config,
    required this.layerResolver,
  }) : super(code: _code);

  @override
  List<Fix> getFixes() => [CreateUseCaseFix(config: config)];

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final subLayer = layerResolver.getSubLayer(resolver.source.fullName);
    if (subLayer != ArchSubLayer.domainRepository) return;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword == null) return;

      for (final member in node.members) {
        if (member is MethodDeclaration && !member.isGetter && !member.isSetter) {
          final methodName = member.name.lexeme;
          if (methodName.isEmpty) continue;

          // --- THIS IS THE FIX ---
          // Use the shared, robust utility to determine the expected file path.
          final expectedFilePath = PathUtils.getUseCaseFilePath(
            methodName: methodName,
            repoPath: resolver.source.fullName,
            config: config,
          );

          if (expectedFilePath != null) {
            final file = File(expectedFilePath);
            if (!file.existsSync()) {
              final expectedClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);
              reporter.atToken(
                member.name,
                _code,
                arguments: [methodName, expectedClassName],
              );
            }
          }
        }
      }
    });
  }
}
