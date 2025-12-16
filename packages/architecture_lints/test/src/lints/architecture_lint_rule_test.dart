import 'dart:io';

import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/definitions/component_definition.dart';
import 'package:architecture_lints/src/engines/file/file_resolver.dart';
import 'package:architecture_lints/src/context/component_context.dart';
import 'package:architecture_lints/src/lints/architecture_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/fakes.dart'; // Ensure this contains FakeCustomLintContext
import '../../helpers/mocks.dart';
import '../../helpers/test_resolver.dart';

// --- Concrete Implementation for Testing ---
// This fixes the "Invalid Override" error by matching the new signature.
class TestArchitectureRule extends ArchitectureRule {
  // Capture arguments to verify logic flow
  ComponentContext? capturedComponent;
  ArchitectureConfig? capturedConfig;

  TestArchitectureRule()
    : super(code: const LintCode(name: 'test_rule', problemMessage: 'test'));

  @override
  void runWithConfig({
    required CustomLintContext context,
    required DiagnosticReporter reporter,
    required CustomLintResolver resolver,
    required ArchitectureConfig config,
    required FileResolver fileResolver,
    ComponentContext? component, // Correct Type
  }) {
    capturedComponent = component;
    capturedConfig = config;
  }
}

void main() {
  group('ArchitectureLintRule', () {
    late TestArchitectureRule rule;
    late CustomLintResolver mockResolver;
    late DiagnosticReporter mockReporter;
    late FakeCustomLintContext fakeContext;
    late Directory tempDir;

    setUp(() {
      rule = TestArchitectureRule();
      mockResolver = MockCustomLintResolver();
      mockReporter = MockDiagnosticReporter();
      fakeContext = FakeCustomLintContext();
      tempDir = Directory.systemTemp.createTempSync('arch_rule_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('startUp should load config and refine component', () async {
      // 1. Setup Architecture Config File
      final configFile = File(p.join(tempDir.path, 'architecture.yaml'))
        ..writeAsStringSync('''
      components:
        .domain:
          path: 'domain'
      ''');

      // 2. Setup Source File
      const sourceCode = 'class User {}';
      final unit = await resolveContent(sourceCode);
      // Hack: Move resolved unit to tempDir structure to match config location
      // In a real integration test, resolveContent would create files relative to architecture.yaml

      // Mock Resolver behavior
      when(
        () => mockResolver.path,
      ).thenReturn(configFile.path); // Use config path to trigger loader
      when(() => mockResolver.getResolvedUnitResult()).thenAnswer((_) async => unit);

      // 3. Run startUp
      await rule.startUp(mockResolver, fakeContext);

      // 4. Verify State Injection
      expect(
        fakeContext.sharedState.containsKey(ArchitectureConfig),
        isTrue,
        reason: 'Config should be loaded',
      );
      expect(
        fakeContext.sharedState.containsKey(FileResolver),
        isTrue,
        reason: 'FileResolver should be initialized',
      );
    });

    test('run should retrieve component from shared state and call runWithConfig', () async {
      // 1. Setup Shared State (Simulate startUp having finished)
      final config = ArchitectureConfig.empty();
      final fileResolver = FileResolver(config);

      // Create a mock ComponentContext
      const componentConfig = ComponentDefinition(id: 'domain', paths: ['domain']);
      const componentContext = ComponentContext(
        filePath: '/lib/domain/user.dart',
        definition: componentConfig,
        debugScoreLog: 'Test Log',
      );

      fakeContext.sharedState[ArchitectureConfig] = config;
      fakeContext.sharedState[FileResolver] = fileResolver;
      // Inject the refined component directly
      fakeContext.sharedState[ComponentContext] = componentContext;

      when(() => mockResolver.path).thenReturn('/lib/domain/user.dart');

      // 2. Run
      rule.run(mockResolver, mockReporter, fakeContext);

      // 3. Verify arguments passed to abstract method
      expect(rule.capturedConfig, equals(config));
      expect(rule.capturedComponent, isNotNull);
      expect(rule.capturedComponent?.id, 'domain');
      expect(rule.capturedComponent?.debugScoreLog, 'Test Log');
    });

    test('run should fallback to FileResolver if Context is missing', () async {
      // 1. Setup Shared State (Config loaded, but Refiner failed/didn't run)
      // Note: We need a config that actually matches something to test fallback
      final configMap = {
        'components': {
          '.domain': {'path': 'domain'},
        },
        'modules': <String, dynamic>{},
      };
      final config = ArchitectureConfig.fromYaml(configMap);
      final fileResolver = FileResolver(config);

      fakeContext.sharedState[ArchitectureConfig] = config;
      fakeContext.sharedState[FileResolver] = fileResolver;
      // NO ComponentContext in shared state

      // 2. Mock Path that matches the config
      when(() => mockResolver.path).thenReturn('lib/domain/file.dart');

      // 3. Run
      rule.run(mockResolver, mockReporter, fakeContext);

      // 4. Verify Fallback Resolution
      expect(rule.capturedComponent, isNotNull, reason: 'Should resolve via path fallback');
      expect(rule.capturedComponent?.id, 'domain');
    });

    test('run should respect excludes', () async {
      // 1. Setup Config with Excludes
      final configMap = {
        'excludes': ['**/*.g.dart'],
        'components': {},
        'modules': <String, dynamic>{},
      };
      final config = ArchitectureConfig.fromYaml(configMap);

      fakeContext.sharedState[ArchitectureConfig] = config;
      fakeContext.sharedState[FileResolver] = FileResolver(config);

      // 2. Mock Path matching exclude
      when(() => mockResolver.path).thenReturn('lib/user.g.dart');

      // 3. Run
      rule.run(mockResolver, mockReporter, fakeContext);

      // 4. Verify runWithConfig was NOT called
      expect(rule.capturedComponent, isNull);
      expect(rule.capturedConfig, isNull);
    });
  });
}
