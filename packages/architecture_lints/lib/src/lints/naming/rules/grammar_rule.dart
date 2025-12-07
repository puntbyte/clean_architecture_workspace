import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/lints/naming/base/naming_base_rule.dart';
import 'package:architecture_lints/src/lints/naming/logic/grammar_logic.dart';
import 'package:architecture_lints/src/utils/nlp/language_analyzer.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class GrammarRule extends NamingBaseRule with GrammarLogic {
  static const _code = LintCode(
    name: 'arch_naming_grammar',
    problemMessage: 'Grammar Violation in {0}: {1}',
    correctionMessage: '{2}',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  // Removed late final _analyzer.
  // We create it on the fly or rely on a static cache if needed.
  // Since we use a static dictionary in LanguageAnalyzer, creating the instance is cheap.

  const GrammarRule() : super(code: _code);

  @override
  void checkName({
    required ClassDeclaration node,
    required ComponentConfig config,
    required DiagnosticReporter reporter,
    required ArchitectureConfig rootConfig, // We need rootConfig for vocabulary
  }) {
    if (config.grammar.isEmpty) return;

    final className = node.name.lexeme;

    // Create analyzer with the current project's vocabulary
    final analyzer = LanguageAnalyzer(
      vocabulary: rootConfig.vocabulary,
    );

    String? failureReason;
    String? failureCorrection;
    bool hasMatch = false;

    for (final grammar in config.grammar) {
      final result = validateGrammar(grammar, className, analyzer);
      if (result.isValid) {
        hasMatch = true;
        break;
      } else {
        failureReason ??= result.reason;
        failureCorrection ??= result.correction;
      }
    }

    if (!hasMatch && failureReason != null) {
      reporter.atToken(
        node.name,
        _code,
        arguments: [
          config.displayName,
          failureReason,
          failureCorrection ?? 'Check grammar configuration.',
        ],
      );
    }
  }
}
