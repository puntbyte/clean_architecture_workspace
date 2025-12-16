import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/schema/constraints/dependency_constraint.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/schema/policies/dependency_policy.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/boundaries/rules/component_dependency_rule.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../helpers/fakes.dart';
import '../../../../helpers/mocks.dart';

class TestComponentDependencyRule extends ComponentDependencyRule {}

AstNode _createDummyNode() => parseString(content: '// dummy').unit;

void main() {
  group('ComponentDependencyRule', () {
    late TestComponentDependencyRule rule;
    late MockDiagnosticReporter mockReporter;
    late MockCustomLintResolver mockResolver;
    late FakeCustomLintContext fakeContext;
    late MockFileResolver mockFileResolver;

    setUpAll(() {
      registerFallbackValue(_createDummyNode());
      registerFallbackValue(FakeLintCode());
    });

    setUp(() {
      rule = TestComponentDependencyRule();
      mockReporter = MockDiagnosticReporter();
      mockResolver = MockCustomLintResolver();
      fakeContext = FakeCustomLintContext();
      mockFileResolver = MockFileResolver();

      when(() => mockReporter.atNode(
        any(),
        any(),
        arguments: any(named: 'arguments'),
        contextMessages: any(named: 'contextMessages'),
        data: any(named: 'data'),
      )).thenReturn(MockDiagnostic());
    });

    ImportDirective createImportNode(String uri) {
      final result = parseString(content: "import '$uri';");
      return result.unit.directives.first as ImportDirective;
    }

    ComponentContext createComponent(String id, String name) {
      return ComponentContext(
        filePath: 'lib/$id.dart',
        definition: ComponentDefinition(id: id, name: name),
      );
    }

    ArchitectureConfig createConfig(List<DependencyPolicy> dependencies) {
      return ArchitectureConfig(
        components: [],
        dependencies: dependencies,
      );
    }

    test('should report error when target is explicitly FORBIDDEN', () {
      final config = createConfig([
        const DependencyPolicy(
          onIds: ['domain'],
          allowed: DependencyConstraint(),
          forbidden: DependencyConstraint(components: ['data']),
        ),
      ]);

      final domainComp = createComponent('domain', 'Domain');
      final dataComp = createComponent('data', 'Data');
      const importedPath = 'lib/data/repo.dart';
      const importUri = 'package:app/data/repo.dart';

      when(() => mockFileResolver.resolve(importedPath)).thenReturn(dataComp);

      final node = createImportNode(importUri);

      rule.checkImport(
        node: node,
        uri: importUri,
        importedPath: importedPath,
        config: config,
        fileResolver: mockFileResolver,
        component: domainComp,
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      // Verify arguments by capturing them
      final captured = verify(() => mockReporter.atNode(
        node.uri,
        any(),
        arguments: captureAny(named: 'arguments'),
      )).captured;

      expect(captured.length, 1);
      final args = captured.first as List;
      expect(args[0], 'Domain');
      expect(args[1], 'Data');
      expect(args[2], isEmpty); // No suggestion for forbidden
    });

    test('should report error when target is NOT in ALLOWED list (Strict Mode)', () {
      final config = createConfig([
        const DependencyPolicy(
          onIds: ['domain'],
          allowed: DependencyConstraint(components: ['shared']),
          forbidden: DependencyConstraint(),
        ),
      ]);

      final domainComp = createComponent('domain', 'Domain');
      final featureComp = createComponent('feature', 'Feature');
      const importedPath = 'lib/feature/logic.dart';
      const importUri = 'package:app/feature/logic.dart';

      when(() => mockFileResolver.resolve(importedPath)).thenReturn(featureComp);

      final node = createImportNode(importUri);

      rule.checkImport(
        node: node,
        uri: importUri,
        importedPath: importedPath,
        config: config,
        fileResolver: mockFileResolver,
        component: domainComp,
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      // FIX: Capture arguments instead of nesting any() inside a list
      final captured = verify(() => mockReporter.atNode(
        node.uri,
        any(),
        arguments: captureAny(named: 'arguments'),
      )).captured;

      expect(captured.length, 1);
      final args = captured.first as List;
      expect(args[0], 'Domain');
      expect(args[1], 'Feature');
      expect(args[2], contains('Allowed dependencies: Shared'));
    });

    test('should PASS when target is in ALLOWED list', () {
      final config = createConfig([
        const DependencyPolicy(
          onIds: ['domain'],
          allowed: DependencyConstraint(components: ['shared']),
          forbidden: DependencyConstraint(),
        ),
      ]);

      final domainComp = createComponent('domain', 'Domain');
      final sharedComp = createComponent('shared', 'Shared');
      const importedPath = 'lib/shared/util.dart';
      const importUri = 'package:app/shared/util.dart';

      when(() => mockFileResolver.resolve(importedPath)).thenReturn(sharedComp);

      final node = createImportNode(importUri);

      rule.checkImport(
        node: node,
        uri: importUri,
        importedPath: importedPath,
        config: config,
        fileResolver: mockFileResolver,
        component: domainComp,
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      verifyNever(() => mockReporter.atNode(any(), any(), arguments: any(named: 'arguments')));
    });

    test('should PASS when target is a child of ALLOWED component', () {
      final config = createConfig([
        const DependencyPolicy(
          onIds: ['domain'],
          allowed: DependencyConstraint(components: ['data']),
          forbidden: DependencyConstraint(),
        ),
      ]);

      final domainComp = createComponent('domain', 'Domain');
      final repoComp = createComponent('data.repository', 'Repository');

      const importedPath = 'lib/data/repo.dart';
      const importUri = 'package:app/data/repo.dart';
      when(() => mockFileResolver.resolve(importedPath)).thenReturn(repoComp);

      final node = createImportNode(importUri);

      rule.checkImport(
        node: node,
        uri: importUri,
        importedPath: importedPath,
        config: config,
        fileResolver: mockFileResolver,
        component: domainComp,
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      verifyNever(() => mockReporter.atNode(any(), any(), arguments: any(named: 'arguments')));
    });

    test('should support Additive Rules', () {
      final config = createConfig([
        const DependencyPolicy(
          onIds: ['domain'],
          allowed: DependencyConstraint(components: ['shared']),
          forbidden: DependencyConstraint(),
        ),
        const DependencyPolicy(
          onIds: ['domain.entity'],
          allowed: DependencyConstraint(components: ['core']),
          forbidden: DependencyConstraint(),
        ),
      ]);

      final currentComp = createComponent('domain.entity', 'Entity');
      final coreComp = createComponent('core', 'Core');
      const corePath = 'core.dart';
      when(() => mockFileResolver.resolve(corePath)).thenReturn(coreComp);

      final node = createImportNode(corePath);

      rule.checkImport(
        node: node,
        uri: corePath,
        importedPath: corePath,
        config: config,
        fileResolver: mockFileResolver,
        component: currentComp,
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      verifyNever(() => mockReporter.atNode(any(), any(), arguments: any(named: 'arguments')));
    });

    test('should ignore non-component imports', () {
      final config = createConfig([
        const DependencyPolicy(
          onIds: ['domain'],
          allowed: DependencyConstraint(components: ['shared']),
          forbidden: DependencyConstraint(),
        ),
      ]);

      final domainComp = createComponent('domain', 'Domain');
      const importedPath = 'lib/random.dart';
      const importUri = 'random.dart';

      when(() => mockFileResolver.resolve(importedPath)).thenReturn(null);

      final node = createImportNode(importUri);

      rule.checkImport(
        node: node,
        uri: importUri,
        importedPath: importedPath,
        config: config,
        fileResolver: mockFileResolver,
        component: domainComp,
        reporter: mockReporter,
        resolver: mockResolver,
        context: fakeContext,
      );

      verifyNever(() => mockReporter.atNode(any(), any(), arguments: any(named: 'arguments')));
    });
  });
}
