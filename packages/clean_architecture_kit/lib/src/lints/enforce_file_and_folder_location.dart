import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:collection/collection.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// A simple record to bundle the configuration for a single location rule.
typedef _RuleDefinition = ({String classType, String namingTemplate, List<String> expectedDirs});

class EnforceFileAndFolderLocation extends DartLintRule {
  static const _code = LintCode(
    name: 'enforce_file_and_folder_location',
    problemMessage: 'A {0} should be located in one of the following directories: {1}.',
    correctionMessage: 'Move the file to a directory that matches the configured paths.',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  final CleanArchitectureConfig config;

  const EnforceFileAndFolderLocation({required this.config}) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    final path = resolver.source.fullName;
    final pathSegments = path.replaceAll(r'\', '/').split('/');

    // 1. Create a list of all location rules based on the config.
    // This makes the lint easily extensible. Just add a new line to add a new rule.
    final ruleDefinitions = <_RuleDefinition>[
      (
        classType: 'Repository Interface',
        namingTemplate: config.naming.repositoryInterface,
        expectedDirs: config.layers.domainRepositoriesPaths,
      ),
      (
        classType: 'UseCase',
        namingTemplate: config.naming.useCase,
        expectedDirs: config.layers.domainUseCasesPaths,
      ),
    ];

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      final path = resolver.source.fullName;
      final pathSegments = path.replaceAll(r'\', '/').split('/');

      // 2. Find the first rule definition that matches the class's name.
      final matchingRule = ruleDefinitions.firstWhereOrNull(
        (rule) => _matches(className, rule.namingTemplate),
      );

      // 3. Guard Clause: If the class name doesn't match any rule, stop.
      if (matchingRule == null) {
        return;
      }

      // 4. Guard Clause: If the config specifies a naming convention but provides
      // no directories for it, don't report an error.
      if (matchingRule.expectedDirs.isEmpty) {
        return;
      }

      // 5. Check if the file's path contains ANY of the required directory names.
      final isLocationValid = matchingRule.expectedDirs.any(pathSegments.contains);

      // 6. If the location is not valid, report the issue.
      if (!isLocationValid) {
        reporter.atToken(
          node.name,
          _code,
          arguments: [matchingRule.classType, matchingRule.expectedDirs.join(', ')],
        );
      }
    });
  }

  bool _matches(String name, String template) {
    // Guard against empty or misconfigured naming templates.
    if (template.isEmpty) {
      return false;
    }

    // Convert the '{{name}}' placeholder into a capturing group for a valid Dart identifier.
    // Allows for names like 'AuthRepository' or 'GetUser_UseCase'.
    final pattern = template.replaceAll('{{name}}', '([A-Z][a-zA-Z0-9_]+)');

    // The ^ and $ anchors ensure the entire string must match the pattern.
    return RegExp('^$pattern\$').hasMatch(name);
  }
}
