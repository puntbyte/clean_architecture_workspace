// lib/src/lints/enforce_semantic_naming.dart (New File)

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:clean_architecture_kit/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_kit/src/lints/clean_architecture_lint_rule.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/models/naming_config.dart';
import 'package:clean_architecture_kit/src/models/rules/naming_rule.dart';
import 'package:clean_architecture_kit/src/utils/natural_language_utils.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// Enforces that classes follow the semantic naming conventions (`grammar`).
///
/// This is an advanced, asynchronous lint that uses natural language processing
/// to validate the grammatical structure of a class name.
class EnforceSemanticNaming extends CleanArchitectureLintRule {
  static const _code = LintCode(
    name: 'enforce_semantic_naming',
    problemMessage: 'The name `{0}` does not follow the required grammatical structure for a {1}.',
  );

  final NaturalLanguageUtils nlpUtils;

  const EnforceSemanticNaming({
    required super.config,
    required super.layerResolver,
    required this.nlpUtils,
  }) : super(code: _code);

  @override
  void run(CustomLintResolver resolver, DiagnosticReporter reporter, CustomLintContext context) {
    // This lint is async, so we can't do the setup directly in `run`.
    // The main logic is inside the async `addClassDeclaration` callback.
    context.registry.addClassDeclaration((node) async {
      // ASYNC
      final filePath = resolver.source.fullName;
      final className = node.name.lexeme;

      // --- Determine the correct rule for the class being analyzed ---
      final (rule: rule, classType: classType) = _getRuleForClass(
        filePath: filePath,
        className: className,
        config: config,
        layerResolver: layerResolver,
      );

      // --- THE DEFINITIVE FIX: Perform a safe null check ---
      // 1. Check if a rule was found for this location/component.
      // 2. Check if that rule actually has a `grammar` property to enforce.
      if (rule == null || rule.grammar == null || rule.grammar!.isEmpty) return;

      final validator = _GrammarValidator(rule.grammar!, nlpUtils);
      final isValid = await validator.isValid(className, node);

      if (!isValid) {
        reporter.atToken(
          node.name,
          LintCode(
            name: _code.name,
            problemMessage:
                'The name `$className` does not follow the grammatical structure `${rule.grammar}` '
                'for a $classType.',
          ),
        );
      }
    });
  }

  /// Determines the single, most appropriate naming rule and class type for a given class.
  ({NamingRule? rule, String? classType}) _getRuleForClass({
    required String filePath,
    required String className,
    required CleanArchitectureConfig config,
    required LayerResolver layerResolver,
  }) {
    final naming = config.naming;
    final actualSubLayer = layerResolver.getSubLayer(filePath);
    if (actualSubLayer == ArchSubLayer.unknown) return (rule: null, classType: null);

    final actualComponent = layerResolver.getSubLayerComponent(filePath, className);
    if (actualComponent != SubLayerComponent.unknown) {
      final rule = _getRuleForComponent(actualComponent, naming);
      return (rule: rule, classType: actualComponent.label);
    }

    final rule = _getRuleForSubLayer(actualSubLayer, naming);
    return (rule: rule, classType: actualSubLayer.label);
  }

  // Helper to select the correct NamingRule for a sub-layer.
  NamingRule? _getRuleForSubLayer(ArchSubLayer subLayer, NamingConfig naming) {
    return switch (subLayer) {
      ArchSubLayer.entity => naming.entity,
      ArchSubLayer.model => naming.model,
      ArchSubLayer.useCase => naming.useCase,
      ArchSubLayer.domainRepository => naming.repository,
      ArchSubLayer.dataRepository => naming.repositoryImplementation,
      ArchSubLayer.dataSource => naming.dataSource,
      ArchSubLayer.manager => naming.manager,
      _ => null,
    };
  }

  // Helper to select the correct NamingRule for a component.
  NamingRule? _getRuleForComponent(SubLayerComponent component, NamingConfig naming) {
    return switch (component) {
      SubLayerComponent.event => naming.event,
      SubLayerComponent.eventImplementation => naming.eventImplementation,
      SubLayerComponent.state => naming.state,
      SubLayerComponent.stateImplementation => naming.stateImplementation,
      _ => null,
    };
  }
}

/// A private helper class for parsing and validating a grammar pattern.
class _GrammarValidator {
  final String grammar;
  final NaturalLanguageUtils nlp;

  _GrammarValidator(this.grammar, this.nlp);

  /// The main validation method. Asynchronously checks if a class name conforms to the grammar.
  Future<bool> isValid(String className, ClassDeclaration node) async {
    // This is a placeholder for a more sophisticated parser. A real implementation
    // would tokenize the grammar string and the className and compare them.
    // For now, we'll implement the logic for a few key grammars.

    final words = nlp.splitPascalCase(className);
    if (words.isEmpty) return false;

    // --- Logic for '{{verb.present}}{{noun.phrase}}' ---
    if (grammar == '{{verb.present}}{{noun.phrase}}') {
      if (words.length < 2) return false; // Must have at least a verb and a noun.
      final isFirstWordVerb = nlp.isVerb(words.first);
      // For a noun phrase, we can simplify and check if the last word is a noun.
      final isLastWordNoun = nlp.isNoun(words.last);
      return isFirstWordVerb && isLastWordNoun;
    }

    // --- Logic for '{{noun.phrase}}(Bloc|Cubit|Manager)' ---
    if (grammar.startsWith('{{noun.phrase}}')) {
      final suffixGroup = RegExp(r'\((.+)\)').firstMatch(grammar);
      if (suffixGroup != null) {
        final allowedSuffixes = suffixGroup.group(1)!.split('|');
        if (allowedSuffixes.any((suffix) => className.endsWith(suffix))) {
          // Check if the part before the suffix is a noun.
          final baseName = className.substring(0, className.length - words.last.length);
          final baseWords = nlp.splitPascalCase(baseName);
          if (baseWords.isNotEmpty) {
            return nlp.isNoun(baseWords.last);
          }
        }
      }
      return false;
    }

    // If grammar is not recognized by this simple parser, assume it's valid for now.
    return true;
  }
}
