import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class _RuleDefinition {
  final String classType;
  final String namingTemplate;
  final List<String> expectedDirs;
  final String? baseClassName;

  const _RuleDefinition({
    required this.classType,
    required this.namingTemplate,
    required this.expectedDirs,
    this.baseClassName,
  });
}

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
    final pathSegments = path.replaceAll(r'\', '/').split('/').map((s) => s.toLowerCase()).toList();

    // 1. Create a list of all location rules based on the config.
    // This makes the lint easily extensible. Just add a new line to add a new rule.
    // Build rules. Here we use the config; add more rules if needed.
    final ruleDefinitions = <_RuleDefinition>[
      _RuleDefinition(
        classType: 'Repository Interface',
        namingTemplate: config.naming.repositoryInterface,
        expectedDirs: config.layers.domainRepositoriesPaths,
        baseClassName: config.inheritance.repositoryBaseName,
      ),

      _RuleDefinition(
        classType: 'UseCase',
        namingTemplate: config.naming.useCase,
        expectedDirs: config.layers.domainUseCasesPaths,
        baseClassName: _combineNonEmpty([
          config.inheritance.unaryUseCaseName,
          config.inheritance.nullaryUseCaseName,
        ]),
      ),
      // Add additional rules here if needed (entities, models, etc.)
    ];

    context.registry.addClassDeclaration((node) {
      final className = node.name.lexeme;
      //final path = resolver.source.fullName;
      //final pathSegments = path.replaceAll(r'\', '/').split('/');

      // Find first matching rule where either the name matches OR inheritance matches.
      final matchingRule = _firstWhereOrNull(ruleDefinitions, (rule) {
        final byName = _matchesName(className, rule.namingTemplate);
        final byInheritance = _extendsOrImplements(node, rule.baseClassName);
        return byName || byInheritance;
      });

      // 3. Guard Clause: If the class name doesn't match any rule, stop.
      if (matchingRule == null) return;

      // 4. Guard Clause: If the config specifies a naming convention but provides
      // no directories for it, don't report an error.
      if (matchingRule.expectedDirs.isEmpty) return;

      // normalize expected dirs
      final normalizedExpected = matchingRule.expectedDirs.map((d) => d.toLowerCase()).toList();

      final isLocationValid = normalizedExpected.any((expectedDir) {
        // Accept exact match or plural form match (e.g. 'usecase' vs 'usecases')
        return pathSegments.any((seg) => seg == expectedDir || seg == '${expectedDir}s');
      });

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

  // Helper: find the first element that satisfies the predicate or return null.
  T? _firstWhereOrNull<T>(List<T> list, bool Function(T) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }

  // If template is empty or the placeholder-only '{{name}}', we treat it as ambiguous.
  bool _matchesName(String className, String template) {
    if (template.trim().isEmpty) return false;
    if (template.trim() == '{{name}}') return false;

    final pattern = template.replaceAll('{{name}}', '([A-Z][a-zA-Z0-9_]+)');
    return RegExp('^$pattern\$').hasMatch(className);
  }

  // Check extends/implements/with for any of the provided base class names.
  bool _extendsOrImplements(ClassDeclaration node, String? baseClassNames) {
    if (baseClassNames == null || baseClassNames.trim().isEmpty) return false;

    final candidates = baseClassNames.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty);

    String? typeToSimpleString(TypeAnnotation? t) {
      if (t == null) return null;
      try {
        return t.toSource().split('<').first.trim();
      } catch (_) {
        return null;
      }
    }

    final extendsType = typeToSimpleString(node.extendsClause?.superclass);
    if (extendsType != null && candidates.any((c) => c == extendsType)) return true;

    final impl = node.implementsClause?.interfaces;
    if (impl != null) {
      for (final iface in impl) {
        final n = typeToSimpleString(iface);
        if (n != null && candidates.any((c) => c == n)) return true;
      }
    }

    final withList = node.withClause?.mixinTypes;
    if (withList != null) {
      for (final mix in withList) {
        final n = typeToSimpleString(mix);
        if (n != null && candidates.any((c) => c == n)) return true;
      }
    }

    return false;
  }

  // Combine multiple optional names into a '|' separated string or return null.
  static String? _combineNonEmpty(Iterable<String?> items) {
    final nonEmpty = items
        .where((s) => s != null && s.trim().isNotEmpty)
        .map((s) => s!.trim())
        .toList();
    if (nonEmpty.isEmpty) return null;
    return nonEmpty.join('|');
  }
}
