// test/helpers/test_lint_runner.dart

import 'dart:async';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_lints/src/lints/architecture_lint_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'fakes.dart';
import 'mocks.dart';

/// A reusable helper for testing contract enforcement lints.
///
/// This helper:
/// - Sets up mock objects for CustomLintContext, CustomLintResolver, etc.
/// - Runs the lint rule
/// - Captures any lint codes reported via atToken()
/// - Returns the list of captured codes for assertions
Future<List<LintCode>> runContractLint({
  required String source,
  required String path,
  required ArchitectureLintRule lint,
  required AnalysisContextCollection contextCollection,
}) async {
  final reporter = MockDiagnosticReporter();
  final resolver = MockCustomLintResolver();
  final context = MockCustomLintContext();
  final registry = MockLintRuleNodeRegistry();

  final capturedCodes = <LintCode>[];
  when(() => reporter.atToken(any(), any(), arguments: any(named: 'arguments'))).thenAnswer((
      invocation,
      ) {
    capturedCodes.add(invocation.positionalArguments[1] as LintCode);
  });

  when(() => resolver.source).thenReturn(FakeSource(fullName: path));
  when(() => context.registry).thenReturn(registry);

  void Function(ClassDeclaration)? capturedCallback;
  when(() => registry.addClassDeclaration(any())).thenAnswer((invocation) {
    capturedCallback = invocation.positionalArguments.first as void Function(ClassDeclaration);
  });

  lint.run(resolver, reporter, context);

  // If the lint returns early (e.g., wrong component type), no callback is registered
  if (capturedCallback == null) return [];

  // Resolve the actual AST from the file system
  final unitResult =
  await contextCollection.contextFor(path).currentSession.getResolvedUnit(path)
  as ResolvedUnitResult;
  final classNodes = unitResult.unit.declarations.whereType<ClassDeclaration>();
  if (classNodes.isEmpty) throw StateError('No class found in test source: $path');

  capturedCallback!(classNodes.first);
  return capturedCodes;
}
