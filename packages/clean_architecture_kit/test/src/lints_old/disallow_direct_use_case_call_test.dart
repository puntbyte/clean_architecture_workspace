import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:clean_architecture_kit/src/lints/disallow_use_case_in_presentation.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';
import '../../helpers/test_utils.dart';

// A mock LayerResolver for this test's specific needs.
class MockLayerResolver extends Mock implements LayerResolver {
  @override
  ArchSubLayer getSubLayer(String path) {
    if (path.contains('/widgets/')) return ArchSubLayer.widget;
    if (path.contains('/managers/')) return ArchSubLayer.manager;
    return ArchSubLayer.unknown;
  }
}

/// A simple visitor to find all method invocations in an AST.
class _MethodInvocationVisitor extends RecursiveAstVisitor<void> {
  final invocations = <MethodInvocation>[];
  @override
  void visitMethodInvocation(MethodInvocation node) {
    invocations.add(node);
    super.visitMethodInvocation(node);
  }
}

/// Helper to get a REAL AstNode instance for mocktail to use as a fallback.
AstNode _getRealAstNodeForFallback() {
  final result = parseString(content: 'void main() {}');
  return result.unit.declarations.first; // Returns a FunctionDeclaration, which is an AstNode.
}

/// Test helper that correctly mocks dependencies and runs the lint.
MockDiagnosticReporter runTest({
  required CleanArchitectureConfig config,
  required String path,
  required String content,
}) {
  final reporter = MockDiagnosticReporter();
  final layerResolver = MockLayerResolver();
  final rule = DisallowUseCaseInPresentation(config: config, layerResolver: layerResolver);
  final resolver = FakeCustomLintResolver(path: path, content: content);
  final registry = TestLintRuleNodeRegistry();
  final context = makeContext(registry);

  rule.run(resolver, reporter, context);

  final parsed = parseString(content: content, throwIfDiagnostics: false, path: path);

  final visitor = _MethodInvocationVisitor();
  parsed.unit.accept(visitor);

  visitor.invocations.forEach(registry.runMethodInvocation);

  return reporter;
}

void main() {
  setUpAll(() {
    // THE FIX: Register a real AstNode instance. This solves the sealed class error.
    registerFallbackValue(_getRealAstNodeForFallback());
    registerFallbackValue(const LintCode(name: 'test', problemMessage: 'test'));
  });

  group('DisallowDirectUseCaseCall Lint Rule', () {
    const useCaseSource = '''
      class GetUserUsecase {
        void call(int id) {}
      }
    ''';

    test('should report when a widget directly calls a use case method', () {
      // THE FIX: The `useCaseNamingTemplate` parameter now exists in `makeConfig`.
      final config = makeConfig(useCaseNamingTemplate: '{{name}}Usecase');
      final reporter = runTest(
        config: config,
        path: '/project/lib/features/auth/presentation/widgets/user_profile.dart',
        content: '''
          $useCaseSource
          
          class UserProfileWidget {
            final GetUserUsecase usecase;
            UserProfileWidget(this.usecase);
            
            void build() {
              usecase.call(123);
            }
          }
        ''',
      );

      verify(() => reporter.atNode(any(that: isA<MethodInvocation>()), any())).called(1);
    });

    test('should NOT report when a presentation manager calls a use case', () {
      final config = makeConfig(useCaseNamingTemplate: '{{name}}Usecase');
      final reporter = runTest(
        config: config,
        path: '/project/lib/features/auth/presentation/managers/user_profile_manager.dart',
        content: '''
          $useCaseSource
          
          class UserProfileManager {
            final GetUserUsecase usecase;
            UserProfileManager(this.usecase);
            
            void fetchUser() {
              usecase.call(123);
            }
          }
        ''',
      );

      verifyNever(() => reporter.atNode(any(), any()));
    });

    test('should NOT report when a widget calls a method on a non-usecase class', () {
      final config = makeConfig(useCaseNamingTemplate: '{{name}}Usecase');
      final reporter = runTest(
        config: config,
        path: '/project/lib/features/auth/presentation/widgets/user_profile.dart',
        content: '''
          class SomeOtherService {
            void doSomething() {}
          }

          class UserProfileWidget {
            final SomeOtherService service;
            UserProfileWidget(this.service);
            
            void build() {
              service.doSomething();
            }
          }
        ''',
      );

      verifyNever(() => reporter.atNode(any(), any()));
    });
  });
}
