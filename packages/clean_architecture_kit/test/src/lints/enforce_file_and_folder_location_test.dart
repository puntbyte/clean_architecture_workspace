import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_kit/src/lints/enforce_file_and_folder_location.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Import all your existing, working helper files
import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';
import '../../helpers/test_utils.dart';

/// Test helper to encapsulate the boilerplate of running the lint rule.
/// This is the core of our working test pattern.
MockDiagnosticReporter runTest({
  required CleanArchitectureConfig config,
  required String path,
  required String content,
}) {
  final reporter = MockDiagnosticReporter();
  final rule = EnforceFileAndFolderLocation(config: config);
  final resolver = FakeCustomLintResolver(path: path, content: content);
  final registry = TestLintRuleNodeRegistry();
  final context = makeContext(registry);

  // The actual execution logic
  rule.run(resolver, reporter, context);
  final parsed = parseString(content: content, throwIfDiagnostics: false);

  // We must iterate over all class declarations in a file.
  for (final declaration in parsed.unit.declarations) {
    if (declaration is ClassDeclaration) {
      registry.runClassDeclaration(declaration);
    }
  }

  return reporter;
}

void main() {
  setUpAll(() {
    // This is required for mocktail to handle the arguments of atToken.
    registerFallbackValue(FakeToken());
    registerFallbackValue(const LintCode(name: 'test', problemMessage: 'test'));
  });

  group('EnforceFileAndFolderLocation', () {
    // ▼▼▼ NEW DEBUGGING TEST ▼▼▼
    // This test will fail if your CleanArchitectureConfig.fromMap is the problem.
    test('config object should be parsed correctly by the test helpers', () {
      // ARRANGE
      final config = makeConfig(domainRepositoriesPaths: ['contracts']);

      // ASSERT
      // This provides a much better error message if the config is wrong.
      expect(
        config.layers.domainRepositoriesPaths,
        isNotEmpty,
        reason: 'domainRepositoriesPaths should not be empty',
      );
      expect(config.layers.domainRepositoriesPaths, equals(['contracts']));
      expect(config.naming.repositoryInterface, equals('{{name}}Repository'));
    });

    // === Your Original Tests, Now More Robust ===

    test('reports when repository interface is not in a configured domain repository path', () {
      // ARRANGE
      final config = makeConfig(domainRepositoriesPaths: ['contracts']);

      // ACT
      final reporter = runTest(
        config: config,
        path: '/project/lib/domain/repositories/auth_repository.dart',
        content: 'abstract class AuthRepository {}',
      );

      // ASSERT
      // We verify the call happened exactly once.
      // This is the most reliable way to check mocktail interactions.
      verify(
        () => reporter.atToken(
          any(),
          any(
            that: isA<LintCode>().having((c) => c.name, 'name', 'enforce_file_and_folder_location'),
          ),
          arguments: any(named: 'arguments'),
        ),
      ).called(1);
    });

    test('does NOT report when repository interface is in a configured path', () {
      // ARRANGE
      final config = makeConfig(domainRepositoriesPaths: ['repositories', 'contracts']);

      // ACT
      final reporter = runTest(
        config: config,
        path: '/project/lib/domain/repositories/auth_repository.dart',
        content: 'abstract class AuthRepository {}',
      );

      // ASSERT
      verifyNever(() => reporter.atToken(any(), any(), arguments: any(named: 'arguments')));
    });

    test('does NOT report for classes that do not match a naming convention', () {
      // ARRANGE
      final config = makeConfig(domainRepositoriesPaths: ['contracts']);

      // ACT
      final reporter = runTest(
        config: config,
        path: '/project/lib/domain/contracts/some_other_class.dart',
        content: 'class SomeHelperClass {}',
      );

      // ASSERT
      verifyNever(() => reporter.atToken(any(), any(), arguments: any(named: 'arguments')));
    });
  });
}
