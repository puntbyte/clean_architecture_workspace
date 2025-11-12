// test/src/lints/missing_use_case_test.dart
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_kit/src/lints/code_generation/missing_use_case.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/utils/path_utils.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';

// Helper function remains unchanged.
Future<void> runMissingUseCaseLint({
  required String repoSource,
  required String repoPath,
  required MissingUseCase lint,
  required MockDiagnosticReporter reporter,
}) async {
  final resolver = MockCustomLintResolver();
  final context = MockCustomLintContext();
  final registry = MockLintRuleNodeRegistry();

  when(() => resolver.source).thenReturn(FakeSource(fullName: repoPath));
  when(() => context.registry).thenReturn(registry);

  void Function(ClassDeclaration)? capturedCallback;
  when(() => registry.addClassDeclaration(any())).thenAnswer((invocation) {
    capturedCallback = invocation.positionalArguments.first as void Function(ClassDeclaration);
  });

  lint.run(resolver, reporter, context);

  final parsed = parseString(content: repoSource, path: repoPath, throwIfDiagnostics: false);
  final classNode = parsed.unit.declarations.whereType<ClassDeclaration>().first;

  expect(capturedCallback, isNotNull);
  capturedCallback!(classNode);
}

void main() {
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

  group('MissingUseCase Lint', () {
    late Directory tempDir;
    late String projectRoot;
    late MockDiagnosticReporter reporter;

    // THE DEFINITIVE FIX: `setUp` and `tearDown` are at the top level of the group,
    // ensuring they run before each test in the nested groups.
    setUp(() async {
      reporter = MockDiagnosticReporter();
      tempDir = await Directory.systemTemp.createTemp('missing_use_case_test_');
      projectRoot = tempDir.path;
      await File(p.join(projectRoot, 'pubspec.yaml')).writeAsString('name: test_project');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    group('when in a feature-first project', () {
      // The variables that depend on `projectRoot` are now correctly
      // initialized inside the test cases or a `setUp` block within this group.
      test('should report a violation when a use case file is missing', () async {
        final config = makeConfig(
          projectStructure: 'feature_first',
          domainRepositoriesPaths: ['contracts'],
        );
        final lint = MissingUseCase(config: config, componentResolver: LayerResolver(config));
        final repoPath = p.join(
          projectRoot,
          'lib',
          'features',
          'auth',
          'domain',
          'contracts',
          'auth_repository.dart',
        );

        await File(repoPath).create(recursive: true);
        const source = 'abstract class AuthRepository { void getUser(int id); }';

        await runMissingUseCaseLint(
          repoSource: source,
          repoPath: repoPath,
          lint: lint,
          reporter: reporter,
        );

        verify(() => reporter.atToken(any(), any())).called(1);
      });

      test('should not report a violation when the use case file exists', () async {
        final config = makeConfig(
          projectStructure: 'feature_first',
          domainRepositoriesPaths: ['contracts'],
        );
        final lint = MissingUseCase(config: config, componentResolver: LayerResolver(config));
        final repoPath = p.join(
          projectRoot,
          'lib',
          'features',
          'auth',
          'domain',
          'contracts',
          'auth_repository.dart',
        );

        await File(repoPath).create(recursive: true);
        const source = 'abstract class AuthRepository { void getUser(int id); }';
        final useCasePath = PathUtils.getUseCaseFilePath(
          methodName: 'getUser',
          repoPath: repoPath,
          config: config,
        );
        await File(useCasePath!).create(recursive: true);

        await runMissingUseCaseLint(
          repoSource: source,
          repoPath: repoPath,
          lint: lint,
          reporter: reporter,
        );

        verifyNever(() => reporter.atToken(any(), any()));
      });
    });

    group('when in a layer-first project', () {
      test('should report a violation when a use case file is missing', () async {
        final config = makeConfig(
          projectStructure: 'layer_first',
          domainRepositoriesPaths: ['repositories'],
        );
        final lint = MissingUseCase(config: config, componentResolver: LayerResolver(config));
        final repoPath = p.join(
          projectRoot,
          'lib',
          'domain',
          'repositories',
          'auth_repository.dart',
        );

        await File(repoPath).create(recursive: true);
        const source = 'abstract class AuthRepository { void saveUser(); }';

        await runMissingUseCaseLint(
          repoSource: source,
          repoPath: repoPath,
          lint: lint,
          reporter: reporter,
        );

        verify(() => reporter.atToken(any(), any())).called(1);
      });

      test('should ignore private methods and not report a violation', () async {
        final config = makeConfig(
          projectStructure: 'layer_first',
          domainRepositoriesPaths: ['repositories'],
        );
        final lint = MissingUseCase(config: config, componentResolver: LayerResolver(config));
        final repoPath = p.join(
          projectRoot,
          'lib',
          'domain',
          'repositories',
          'auth_repository.dart',
        );

        await File(repoPath).create(recursive: true);
        const source = 'abstract class AuthRepository { void _privateHelper(); }';

        await runMissingUseCaseLint(
          repoSource: source,
          repoPath: repoPath,
          lint: lint,
          reporter: reporter,
        );

        verifyNever(() => reporter.atToken(any(), any()));
      });
    });
  });
}
