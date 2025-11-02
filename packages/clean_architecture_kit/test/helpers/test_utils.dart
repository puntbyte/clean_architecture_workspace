import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/expect.dart';

/// A test implementation of the LintRuleNodeRegistry that allows us to
/// manually trigger the visitors after the `run` method has been called.
class TestLintRuleNodeRegistry implements LintRuleNodeRegistry {
  // Callback for ClassDeclaration visitor
  void Function(ClassDeclaration)? _classCb;

  void Function(MethodInvocation)? _methodInvocationCb;

  // ▼▼▼ ADD THIS SECTION ▼▼▼
  // Callback for MethodDeclaration visitor
  void Function(MethodDeclaration)? _methodCb;

  @override
  void addClassDeclaration(void Function(ClassDeclaration) cb) {
    _classCb = cb;
  }

  @override
  void addMethodInvocation(void Function(MethodInvocation) cb) {
    _methodInvocationCb = cb;
  }

  void runMethodInvocation(MethodInvocation node) {
    _methodInvocationCb?.call(node);
  }

  // ▼▼▼ AND THIS METHOD ▼▼▼
  @override
  void addMethodDeclaration(void Function(MethodDeclaration) cb) {
    _methodCb = cb;
  }

  // This is the public method our test helper calls for class-based lints.
  void runClassDeclaration(ClassDeclaration node) {
    _classCb?.call(node);
  }

  // ▼▼▼ AND THIS PUBLIC METHOD ▼▼▼
  // This is the public method our `DataSourcePurity` test helper needs to call.
  void runMethodDeclaration(MethodDeclaration node) {
    _methodCb?.call(node);
  }

  // This is required to satisfy the interface, but we don't need to implement
  // every single `add...` method, as mocktail will handle the rest.
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // This can be left empty. It prevents "missing implementation" errors
    // for all the other `add...` methods we don't explicitly use in tests.
  }
}

CustomLintContext makeContext(TestLintRuleNodeRegistry registry) {
  void addPostRunCallback(void Function() cb) => cb();
  final sharedState = <Object, Object?>{};

  return CustomLintContext(registry, addPostRunCallback, sharedState, null);
}

// test/helpers/test_utils.dart

// A simple helper extension to make test assertions cleaner.
extension ResolvedUnitResultExt on Future<ResolvedUnitResult> {
  /// Asserts that the resolved unit has an error with the given [code]
  /// and that the highlighted portion of the error contains the string [at].
  Future<void> withError(LintCode code, {required String at}) async {
    final result = await this;
    final errors = result.errors;

    expect(errors, isNotEmpty, reason: 'Expected to find lints, but found none.');

    final matchingError = errors.firstWhere(
      (e) => e.errorCode.name == code.name,
      orElse: () => throw StateError('No lint found with code ${code.name}'),
    );

    final highlightedText = result.content.substring(
      matchingError.offset,
      matchingError.offset + matchingError.length,
    );
    expect(highlightedText, contains(at));
  }

  /// Asserts that the resolved unit has no lint errors.
  Future<void> withNoIssues() async {
    final result = await this;
    expect(
      result.errors,
      isEmpty,
      reason: 'Expected no issues, but found ${result.errors.length}.',
    );
  }
}
