import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/lints/naming/base/naming_base_rule.dart';
import 'package:architecture_lints/src/lints/naming/logic/grammar_logic.dart';
import 'package:architecture_lints/src/utils/message_utils.dart';
import 'package:architecture_lints/src/utils/nlp/language_analyzer.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dictionaryx/dictionary_msa.dart';

class GrammarRule extends NamingBaseRule with GrammarLogic {
  static const _code = LintCode(
    name: 'arch_naming_grammar',
    problemMessage: 'Grammar Violation in {0}: {1}',
    correctionMessage: '{2}',
    errorSeverity: DiagnosticSeverity.WARNING,
  );

  late final LanguageAnalyzer _analyzer;

  GrammarRule() : super(code: _code) {
    _analyzer = LanguageAnalyzer(dictionary: DictionaryMSA());
  }

  @override
  void checkName({
    required ClassDeclaration node,
    required ComponentConfig component,
    required DiagnosticReporter reporter,
    required ArchitectureConfig config,
  }) {
    if (component.grammar.isEmpty) return;

    final className = node.name.lexeme;

    String? failureReason;
    String? failureCorrection;
    var hasMatch = false;

    for (final grammar in component.grammar) {
      // Use logic mixin
      final result = validateGrammar(grammar, className, _analyzer);
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
          MessageUtils.humanizeComponent(component),
          failureReason,
          failureCorrection ?? 'Check grammar configuration.',
        ],
      );
    }
  }
}
