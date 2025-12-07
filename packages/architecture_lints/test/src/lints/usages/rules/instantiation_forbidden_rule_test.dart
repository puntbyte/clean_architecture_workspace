import 'dart:io';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/enums/usage_kind.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/usage_config.dart';
import 'package:architecture_lints/src/config/schema/usage_constraint.dart';
import 'package:architecture_lints/src/core/resolver/file_resolver.dart';
import 'package:architecture_lints/src/lints/usages/rules/instantiation_forbidden_rule.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class TestWrapper extends DartLintRule {
  final DartLintRule delegate;
  final ArchitectureConfig mockConfig;

  TestWrapper(this.delegate, this.mockConfig) : super(code: delegate.code);

  @override
  Future<void> startUp(CustomLintResolver r, CustomLintContext c) async {
    c.sharedState[ArchitectureConfig] = mockConfig;
    c.sharedState[FileResolver] = FileResolver(mockConfig);
    await super.startUp(r, c);
  }

  @override
  void run(CustomLintResolver r, DiagnosticReporter rep, CustomLintContext c) =>
      delegate.run(r, rep, c);
}

void main() {
  group('InstantiationForbiddenRule', () {
    late Directory tempDir;

    setUp(() => tempDir = Directory.systemTemp.createTempSync('usage_test_'));
    tearDown(() => tempDir.deleteSync(recursive: true));

    Future<List<Diagnostic>> run(ArchitectureConfig config, String content) async {
      final file = File(p.join(tempDir.path, 'lib/domain/usecase.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync(content);

      File(p.join(tempDir.path, 'lib/data/repo.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('class AuthRepository {}');

      final result = await resolveFile(path: p.normalize(file.absolute.path));
      return TestWrapper(
        const InstantiationForbiddenRule(),
        config,
      ).testRun(result as ResolvedUnitResult);
    }

    test('should report error when instantiating a forbidden component', () async {
      const config = ArchitectureConfig(
        components: [
          ComponentConfig(id: 'usecase', paths: ['domain']),
          ComponentConfig(id: 'repository', paths: ['data']),
        ],
        usages: [
          UsageConfig(
            onIds: ['usecase'],
            forbidden: [
              UsageConstraint(kind: UsageKind.instantiation, components: ['repository']),
            ],
          ),
        ],
      );

      final errors = await run(config, '''
        import '../data/repo.dart';
        class UseCase {
          void call() {
            final repo = AuthRepository(); // Violation
          }
        }
      ''');

      expect(errors, hasLength(1));
      // FIX: Match case-insensitive or the capitalized output seen in logs
      expect(
        errors.first.message,
        matches('Direct instantiation of "[Rr]epository" is forbidden'),
      );
    });
  });
}
