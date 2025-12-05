import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/enums/annotation_mode.dart';
import 'package:architecture_lints/src/config/schema/annotation_config.dart';
import 'package:architecture_lints/src/config/schema/annotation_constraint.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/metadata/rules/annotation_forbidden_rule.dart';
import 'package:architecture_lints/src/lints/metadata/rules/annotation_required_rule.dart';
import 'package:architecture_lints/src/lints/metadata/rules/annotation_strict_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// Helper to inject config
class TestRuleWrapper<T extends DartLintRule> extends DartLintRule {
  final T delegate;
  final ArchitectureConfig mockConfig;

  TestRuleWrapper(this.delegate, this.mockConfig) : super(code: delegate.code);

  @override
  Future<void> startUp(
    CustomLintResolver resolver,
    CustomLintContext context,
  ) async {
    context.sharedState[ArchitectureConfig] = mockConfig;
    context.sharedState[FileResolver] = FileResolver(mockConfig);
    await super.startUp(resolver, context);
  }

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    delegate.run(resolver, reporter, context);
  }
}

void main() {
  group('Annotation Rules', () {
    late Directory tempDir;
    const entityConfig = ComponentConfig(id: 'entity', paths: ['domain']);

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('annot_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    Future<List<Diagnostic>> runRule(
      DartLintRule rule,
      ArchitectureConfig config,
      String content,
    ) async {
      const relativePath = 'lib/domain/entity.dart';
      final pathParts = relativePath.split('/');
      final fullPath = p.joinAll([tempDir.path, ...pathParts]);

      final file = File(fullPath)
        ..createSync(recursive: true)
        ..writeAsStringSync(content);

      final normalizedPath = p.normalize(file.absolute.path);

      final result = await resolveFile(path: normalizedPath);
      final wrapper = TestRuleWrapper(rule, config);
      return wrapper.testRun(result as ResolvedUnitResult);
    }

    group('AnnotationForbiddenRule', () {
      test('should report warning when class uses a forbidden annotation', () async {
        const config = ArchitectureConfig(
          components: [entityConfig],
          annotations: [
            AnnotationConfig(
              onIds: ['entity'],
              forbidden: [
                AnnotationConstraint(types: ['JsonSerializable']),
              ],
              required: [],
              allowed: [],
            ),
          ],
        );

        final errors = await runRule(
          const AnnotationForbiddenRule(),
          config,
          '''
          @JsonSerializable()
          class UserEntity {} 
          ''',
        );

        expect(errors, hasLength(1));
        expect(
          errors.first.message,
          contains('Forbidden annotation: "JsonSerializable"'),
        );
      });

      test('should not report warning when class uses allowed annotations', () async {
        const config = ArchitectureConfig(
          components: [entityConfig],
          annotations: [
            AnnotationConfig(
              onIds: ['entity'],
              forbidden: [
                AnnotationConstraint(types: ['Forbidden']),
              ],
              required: [],
              allowed: [],
            ),
          ],
        );

        final errors = await runRule(
          const AnnotationForbiddenRule(),
          config,
          '''
          @Allowed()
          class UserEntity {} 
          ''',
        );

        expect(errors, isEmpty);
      });
    });

    group('AnnotationRequiredRule', () {
      test('should report warning when class is missing a required annotation', () async {
        const config = ArchitectureConfig(
          components: [entityConfig],
          annotations: [
            AnnotationConfig(
              onIds: ['entity'],
              required: [
                AnnotationConstraint(types: ['Immutable']),
              ],
              allowed: [],
              forbidden: [],
            ),
          ],
        );

        final errors = await runRule(
          const AnnotationRequiredRule(),
          config,
          'class UserEntity {}',
        );

        expect(errors, hasLength(1));
        // FIX: The message includes the '@' symbol now
        expect(
          errors.first.message,
          contains('Missing required annotation: "@Immutable"'),
        );
      });

      test('should not report warning when required annotation is present', () async {
        const config = ArchitectureConfig(
          components: [entityConfig],
          annotations: [
            AnnotationConfig(
              onIds: ['entity'],
              required: [
                AnnotationConstraint(types: ['Immutable']),
              ],
              allowed: [],
              forbidden: [],
            ),
          ],
        );

        final errors = await runRule(
          const AnnotationRequiredRule(),
          config,
          '''
          @Immutable()
          class UserEntity {}
          ''',
        );

        expect(errors, isEmpty);
      });
    });

    group('AnnotationStrictRule', () {
      test('should report warning for unlisted annotation in strict mode', () async {
        const config = ArchitectureConfig(
          components: [entityConfig],
          annotations: [
            AnnotationConfig(
              onIds: ['entity'],
              mode: AnnotationMode.strict,
              allowed: [
                AnnotationConstraint(types: ['Allowed']),
              ],
              required: [],
              forbidden: [],
            ),
          ],
        );

        final errors = await runRule(
          const AnnotationStrictRule(),
          config,
          '''
          @Allowed()
          @UnknownAnnotation() // Should be flagged
          class UserEntity {}
          ''',
        );

        expect(errors, hasLength(1));
        expect(
          errors.first.message,
          contains('Annotation "UnknownAnnotation" is not allowed'),
        );
      });

      test('should allow required annotations in strict mode', () async {
        const config = ArchitectureConfig(
          components: [entityConfig],
          annotations: [
            AnnotationConfig(
              onIds: ['entity'],
              mode: AnnotationMode.strict,
              required: [
                AnnotationConstraint(types: ['Required']),
              ],
              allowed: [],
              forbidden: [],
            ),
          ],
        );

        final errors = await runRule(
          const AnnotationStrictRule(),
          config,
          '''
          @Required()
          class UserEntity {}
          ''',
        );

        expect(errors, isEmpty);
      });
    });
  });
}
