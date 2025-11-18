// lib/srcs/lints/structure/missing_use_case.dart

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/fixes/create_use_case_fix.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:clean_architecture_lints/src/utils/path_utils.dart';
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

  // A unique key to store the ResolvedUnitResult in the shared state.
  static final _unitResultKey = Object();

  @override
  List<Fix> getFixes() => [CreateUseCaseFix(config: config)];

  /// In the `startUp` phase, we resolve the unit and store it in the shared
  /// state so that the `run` method can access it synchronously.
  @override
  Future<void> startUp(CustomLintResolver resolver, CustomLintContext context) async {
    // Only resolve the unit once per file analysis.
    if (context.sharedState.containsKey(_unitResultKey)) return;
    context.sharedState[_unitResultKey] = await resolver.getResolvedUnitResult();

    // Call super.startUp to ensure the visitor is registered.
    await super.startUp(resolver, context);
  }

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final component = layerResolver.getComponent(resolver.source.fullName);
    if (component != ArchComponent.contract) return;

    // Retrieve the resolved unit from the shared state. If it's not there,
    // something went wrong, and we should bail out.
    final resolvedUnit = context.sharedState[_unitResultKey] as ResolvedUnitResult?;
    if (resolvedUnit == null) return;

    final resourceProvider = resolvedUnit.session.analysisContext.contextRoot.resourceProvider;

    context.registry.addClassDeclaration((node) {
      if (node.abstractKeyword == null) return;

      for (final member in node.members) {
        if (member is MethodDeclaration &&
            !member.isGetter &&
            !member.isSetter &&
            !member.name.lexeme.startsWith('_')) {
          _checkMethodForMissingUseCase(
            method: member,
            repoPath: resolver.source.fullName,
            reporter: reporter,
            resourceProvider: resourceProvider,
          );
        }
      }
    });
  }

  void _checkMethodForMissingUseCase({
    required MethodDeclaration method,
    required String repoPath,
    required DiagnosticReporter reporter,
    required ResourceProvider resourceProvider,
  }) {
    final methodName = method.name.lexeme;

    final expectedFilePath = PathUtils.getUseCaseFilePath(
      methodName: methodName,
      repoPath: repoPath,
      config: config,
    );
    if (expectedFilePath == null) return;

    if (!resourceProvider.getFile(expectedFilePath).exists) {
      final expectedClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);
      reporter.atToken(method.name, _code, arguments: [methodName, expectedClassName]);
    }
  }
}
