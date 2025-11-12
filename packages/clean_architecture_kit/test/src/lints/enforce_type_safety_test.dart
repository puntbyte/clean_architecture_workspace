// test/src/lints/enforce_type_safety_test.dart

import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/structure/enforce_type_safety.dart';
import 'package:clean_architecture_kit/src/models/rules/parameter_rule.dart';
import 'package:clean_architecture_kit/src/models/rules/return_rule.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

/// A simple visitor to find and act on all MethodDeclarations in a file.
class _MethodVisitor extends RecursiveAstVisitor<void> {
  final void Function(MethodDeclaration) onVisit;

  _MethodVisitor({required this.onVisit});

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    onVisit(node);
    super.visitMethodDeclaration(node);
  }
}

/// A test helper that runs the lint and captures all diagnostic reports.
Future<List<Map<String, dynamic>>> runTypeSafetyLintAndCapture({
  required EnforceTypeSafety lint,
  required MockDiagnosticReporter reporter,
  required String filePath,
  required String source,
}) async {
  final resolver = MockCustomLintResolver();
  final context = MockCustomLintContext();
  final registry = MockLintRuleNodeRegistry();

  when(() => resolver.source).thenReturn(FakeSource(fullName: filePath));
  when(() => context.registry).thenReturn(registry);

  void Function(MethodDeclaration)? capturedCallback;
  when(() => registry.addMethodDeclaration(any())).thenAnswer((invocation) {
    capturedCallback = invocation.positionalArguments.first as void Function(MethodDeclaration);
  });

  final captured = <Map<String, dynamic>>[];
  when(() => reporter.atNode(any(), any())).thenAnswer((invocation) {
    captured.add({'fn': 'atNode'});
  });
  when(() => reporter.atToken(any(), any())).thenAnswer((invocation) {
    captured.add({'fn': 'atToken'});
  });

  lint.run(resolver, reporter, context);

  final parseResult = parseString(content: source, path: filePath, throwIfDiagnostics: false);
  expect(capturedCallback, isNotNull, reason: 'Expected addMethodDeclaration to be registered.');

  parseResult.unit.visitChildren(_MethodVisitor(onVisit: capturedCallback!));

  return captured;
}

void main() {
  // Definitive, correct setUpAll block.
  setUpAll(() {
    registerFallbackValue(FakeToken());
    registerFallbackValue(FakeLintCode());
    registerFallbackValue(FakeSourceRange());

    // Create a real, concrete instance of an AstNode to use as a fallback.
    // We parse a minimal, valid snippet of code to do this.
    final parseResult = parseString(
      content: 'class Dummy {}',
      throwIfDiagnostics: false,
    );

    // The CompilationUnit is the root of the AST and is a valid AstNode.
    final astRoot = parseResult.unit;

    // Register this real instance.
    registerFallbackValue(astRoot);
  });

  group('EnforceTypeSafety', () {
    late Directory tempDir;
    late String projectRoot;
    late MockDiagnosticReporter reporter;

    setUp(() async {
      reporter = MockDiagnosticReporter();
      tempDir = await Directory.systemTemp.createTemp('enforce_type_safety_test_');
      projectRoot = tempDir.path;
      await File(p.join(projectRoot, 'pubspec.yaml')).writeAsString('name: test_project');
    });

    tearDown(() async => tempDir.delete(recursive: true));

    group('when checking return types', () {
      late String repoPath;
      const returnRule = ReturnRule(type: 'FutureEither', where: ['domain_repository']);
      final config = makeConfig(
        projectStructure: 'layer_first',
        domainRepositoriesPaths: ['repositories'],
        returnRules: [returnRule],
      );
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));

      setUp(() async {
        repoPath = p.join(projectRoot, 'lib', 'domain', 'repositories', 'user_repository.dart');
        await File(repoPath).parent.create(recursive: true);
      });

      test('should report a violation when the return type is incorrect', () async {
        const source = 'abstract class UserRepository { Future<User> getUser(int id); }';
        final captured = await runTypeSafetyLintAndCapture(
          lint: lint,
          reporter: reporter,
          filePath: repoPath,
          source: source,
        );
        expect(captured.where((c) => c['fn'] == 'atNode'), isNotEmpty);
      });

      test('should report a violation when the return type is incorrect', () async {
        const source = 'abstract class UserRepository { Future<User> getUser(int id); }';
        final captured = await runTypeSafetyLintAndCapture(
          lint: lint,
          reporter: reporter,
          filePath: repoPath,
          source: source,
        );
        expect(captured.where((c) => c['fn'] == 'atNode'), isNotEmpty);
      });

      test('should not report a violation when the return type is correct', () async {
        const source = 'abstract class UserRepository { FutureEither<User> getUser(int id); }';
        final captured = await runTypeSafetyLintAndCapture(
          lint: lint,
          reporter: reporter,
          filePath: repoPath,
          source: source,
        );
        expect(captured, isEmpty, reason: 'Expected no reports for correct code.');
      });

      test('should not report a violation for setters', () async {
        const source = 'abstract class UserRepository { set user(User u); }';
        final captured = await runTypeSafetyLintAndCapture(
          lint: lint,
          reporter: reporter,
          filePath: repoPath,
          source: source,
        );
        expect(captured, isEmpty, reason: 'Setters should be ignored for return type rules.');
      });
    });

    group('when checking parameters', () {
      late String repoPath;
      const paramRule = ParameterRule(type: 'Id', where: ['domain_repository'], identifier: 'id');
      final config = makeConfig(
        projectStructure: 'layer_first',
        domainRepositoriesPaths: ['repositories'], // Correctly configure the path
        parameterRules: [paramRule],
      );
      final lint = EnforceTypeSafety(config: config, layerResolver: LayerResolver(config));

      setUp(() async {
        repoPath = p.join(projectRoot, 'lib', 'domain', 'repositories', 'user_repository.dart');
        await File(repoPath).parent.create(recursive: true);
      });

      test('should report a violation when a matching parameter has the wrong type', () async {
        const source = 'abstract class UserRepository { void getUser(int userId); }';
        final captured = await runTypeSafetyLintAndCapture(
          lint: lint,
          reporter: reporter,
          filePath: repoPath,
          source: source,
        );
        expect(captured.where((c) => c['fn'] == 'atNode'), isNotEmpty);
      });

      test('should not report a violation when the parameter type is correct', () async {
        const source = 'abstract class UserRepository { void getUser(Id userId); }';
        final captured = await runTypeSafetyLintAndCapture(
          lint: lint,
          reporter: reporter,
          filePath: repoPath,
          source: source,
        );
        expect(captured, isEmpty);
      });

      test('should not report a violation when no parameter name matches the identifier', () async {
        const source = 'abstract class UserRepository { void findUser(String name); }';
        final captured = await runTypeSafetyLintAndCapture(
          lint: lint,
          reporter: reporter,
          filePath: repoPath,
          source: source,
        );
        expect(captured, isEmpty);
      });
    });
  });
}
