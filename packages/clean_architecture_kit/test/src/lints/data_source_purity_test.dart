import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_kit/src/lints/data_source_purity.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/layer_resolver.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

// Import all your existing, working helper files
import '../../helpers/fakes.dart';
import '../../helpers/mocks.dart';
import '../../helpers/test_data.dart';
import '../../helpers/test_utils.dart';

// A pure mock class. We will define its behavior using `when`.
class MockLayerResolver extends Mock implements LayerResolver {}

// Helper to get a REAL TypeAnnotation instance for mocktail's fallback.
TypeAnnotation _getRealTypeAnnotationForFallback() {
  final result = parseString(content: 'void main(String s) {}');
  final function = result.unit.declarations.first as FunctionDeclaration;
  final parameter =
      function.functionExpression.parameters!.parameters.first as SimpleFormalParameter;
  return parameter.type!;
}

/// Test helper that correctly mocks dependencies and runs the lint.
MockDiagnosticReporter runTest({
  required CleanArchitectureConfig config,
  required String path,
  required String content,
}) {
  final reporter = MockDiagnosticReporter();
  final layerResolver = MockLayerResolver();

  // ▼▼▼ THIS IS THE CRITICAL FIX ▼▼▼
  // We MUST stub the behavior of the mocked LayerResolver.
  // When getSubLayer is called with a data source path, return the correct sublayer.
  when(
    () => layerResolver.getSubLayer(any(that: contains('/data/sources/'))),
  ).thenReturn(ArchSubLayer.dataSource);
  // For any other path, return unknown so the lint's guard clause works correctly.
  when(
    () => layerResolver.getSubLayer(any(that: isNot(contains('/data/sources/')))),
  ).thenReturn(ArchSubLayer.unknown);

  // When getLayer is called for an entity's path, return the correct layer.
  when(
    () => layerResolver.getLayer(any(that: contains('/domain/entities/'))),
  ).thenReturn(ArchLayer.domain);
  // For any other path, return a different layer.
  when(
    () => layerResolver.getLayer(any(that: isNot(contains('/domain/entities/')))),
  ).thenReturn(ArchLayer.data);

  final rule = DataSourcePurity(config: config, layerResolver: layerResolver);
  final resolver = FakeCustomLintResolver(path: path, content: content);
  final registry = TestLintRuleNodeRegistry();
  final context = makeContext(registry);

  rule.run(resolver, reporter, context);

  // NOTE: The type resolution in tests is complex. Your lint relies on
  // `type.element.library.source.fullName`, which requires a fully resolved AST.
  // The basic `parseString` doesn't do this. So, we manually provide the source path
  // to the resolver mock to simulate it.
  final parsed = parseString(content: content, throwIfDiagnostics: false, path: path);

  for (final declaration in parsed.unit.declarations) {
    if (declaration is ClassDeclaration) {
      for (final member in declaration.members) {
        if (member is MethodDeclaration) {
          registry.runMethodDeclaration(member);
        }
      }
    }
  }

  return reporter;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_getRealTypeAnnotationForFallback());
    registerFallbackValue(const LintCode(name: 'test', problemMessage: 'test'));
  });

  group('DataSourcePurity Lint Rule', () {
    // We create full, valid Dart code here to help the analyzer.
    const userEntitySource = 'class UserEntity {}';
    const userModelSource = 'class UserModel {}';

    test('should report when a data source method returns a domain Entity', () {
      final config = makeConfig(domainEntitiesPaths: ['entities']);
      final reporter = runTest(
        config: config,
        path: '/project/lib/data/sources/user_data_source.dart',
        content:
            '''
          // The lint needs to resolve the type, so we simulate the import path
          import '/project/lib/domain/entities/user_entity.dart';
          $userEntitySource
          
          abstract class UserDataSource { 
            Future<UserEntity> getUser(); 
          }
        ''',
      );

      verify(() => reporter.atNode(any(that: isA<TypeAnnotation>()), any())).called(1);
    });

    test('should report when a data source method has a domain Entity as a parameter', () {
      final config = makeConfig(domainEntitiesPaths: ['entities']);
      final reporter = runTest(
        config: config,
        path: '/project/lib/data/sources/user_data_source.dart',
        content:
            '''
          import '/project/lib/domain/entities/user_entity.dart';
          $userEntitySource

          abstract class UserDataSource { 
            Future<void> saveUser(UserEntity user); 
          }
        ''',
      );

      verify(() => reporter.atNode(any(that: isA<TypeAnnotation>()), any())).called(1);
    });

    test('should NOT report when a data source returns a data Model', () {
      final config = makeConfig(domainEntitiesPaths: ['entities']);
      final reporter = runTest(
        config: config,
        path: '/project/lib/data/sources/user_data_source.dart',
        content:
            '''
          import '/project/lib/data/models/user_model.dart';
          $userModelSource
          
          abstract class UserDataSource { 
            Future<UserModel> getUser(); 
          }
        ''',
      );

      verifyNever(() => reporter.atNode(any(), any()));
    });

    test('should NOT report for files outside of the data source layer', () {
      final config = makeConfig(domainEntitiesPaths: ['entities']);
      final reporter = runTest(
        config: config,
        path: '/project/lib/domain/repositories/user_repository.dart',
        content:
            '''
          import '/project/lib/domain/entities/user_entity.dart';
          $userEntitySource

          abstract class UserRepository { 
            Future<UserEntity> getUser(); 
          }
        ''',
      );

      verifyNever(() => reporter.atNode(any(), any()));
    });
  });
}
