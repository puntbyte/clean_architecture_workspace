import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/schema/enums/relationship_kind.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/policies/relationship_policy.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/consistency/logic/relationship_logic.dart';
import 'package:architecture_lints/src/lints/naming/logic/naming_logic.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../../helpers/test_resolver.dart';

class MockFileResolver extends Mock implements FileResolver {}

class RelationshipLogicTester with NamingLogic, RelationshipLogic {}

void main() {
  group('RelationshipLogic', () {
    late RelationshipLogicTester tester;
    late MockFileResolver mockResolver;

    setUp(() {
      tester = RelationshipLogicTester();
      mockResolver = MockFileResolver();
    });

    test('extractCoreName should extract name from pattern', () {
      const context = ComponentContext(
        filePath: '',
        definition: ComponentDefinition(
          id: 'entity',
          // FIX: Use raw string r'${name}'
          patterns: [r'${name}Entity'],
        ),
      );

      expect(tester.extractCoreName('UserEntity', context), 'User');
      expect(tester.extractCoreName('User', context), isNull); // Mismatch
    });

    test('generateTargetClassName should replace placeholders', () {
      const targetConfig = ComponentDefinition(
        id: 'model',
        patterns: [r'${name}Model'],
      );

      expect(tester.generateTargetClassName('User', targetConfig), 'UserModel');
    });

    test('toSnakeCase should handle pascal case', () {
      expect(tester.toSnakeCase('User'), 'user');
      expect(tester.toSnakeCase('UserModel'), 'user_model');
      expect(tester.toSnakeCase('HTMLParser'), 'html_parser');
    });

    group('findMissingTarget', () {
      test('should find target if path exists (Method -> File)', () async {
        // 1. Setup Source: Port file with method
        // Note: We don't need real files for logic test if we mock paths,
        // but resolveContent helps get real AST node.
        final unit = await resolveContent('class AuthPort { void login() {} }');
        final clazz = unit.unit.declarations.first as ClassDeclaration;
        final method = clazz.members.first as MethodDeclaration;

        // 2. Setup Config
        const sourceConfig = ComponentDefinition(
          id: 'domain.port',
          paths: ['domain/ports'],
          patterns: [r'${name}'], // Naive pattern
        );
        const targetConfig = ComponentDefinition(
          id: 'domain.usecase',
          paths: ['domain/usecases'],
          patterns: [r'${name}'], // Naive pattern
        );

        const config = ArchitectureConfig(
          components: [sourceConfig, targetConfig],
          relationships: [
            RelationshipPolicy(
              onIds: ['domain.port'],
              kind: RelationshipKind.method,
              targetComponent: 'domain.usecase',
              action: 'create_usecase',
            ),
          ],
        );

        final currentContext = ComponentContext(
          // Simulate being in correct path
          filePath: p.join('root', 'lib', 'domain', 'ports', 'auth_port.dart'),
          definition: sourceConfig,
        );

        // 3. Run
        final result = tester.findMissingTarget(
          node: method,
          config: config,
          currentComponent: currentContext,
          fileResolver: mockResolver,
          currentFilePath: currentContext.filePath,
        );

        // 4. Verify
        // Logic calculates target path based on relative structure.
        // auth_port.dart in domain/ports -> ../usecases/login.dart

        expect(result.target, isNotNull);
        expect(result.target!.coreName, 'Login');
        expect(result.target!.path, endsWith(p.join('domain', 'usecases', 'login.dart')));
      });
    });
  });
}
