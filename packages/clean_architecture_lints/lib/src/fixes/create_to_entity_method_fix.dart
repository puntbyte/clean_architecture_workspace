// lib/src/fixes/create_to_entity_method_fix.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/analysis/layer_resolver.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/codegen/syntax_builder.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_style/dart_style.dart';

/// A quick fix that generates or corrects the `toEntity()` method in a Model class.
class CreateToEntityMethodFix extends DartFix {
  final ArchitectureConfig config;

  CreateToEntityMethodFix({required this.config});

  @override
  void run(
      CustomLintResolver resolver,
      ChangeReporter reporter,
      CustomLintContext context,
      Diagnostic diagnostic,
      List<Diagnostic> others,
      ) {
    context.addPostRunCallback(() async {
      final resolvedUnit = await resolver.getResolvedUnitResult();
      final node = resolvedUnit.unit.nodeCovering(offset: diagnostic.offset);

      final modelNode = node?.thisOrAncestorOfType<ClassDeclaration>();
      if (modelNode == null) return;

      final classElement = modelNode.declaredFragment?.element;
      if (classElement == null) return;

      final layerResolver = LayerResolver(config);

      // Find the Entity supertype
      final entitySupertype = classElement.allSupertypes.firstWhereOrNull((st) {
        final source = st.element.library.firstFragment.source;
        return layerResolver.getComponent(source.fullName) == ArchComponent.entity;
      });

      final entityElement = entitySupertype?.element;
      if (entityElement is! InterfaceElement) return;

      final entityName = entityElement.name; // Analyzer 8.0.0: name is simple String (or null)
      // ignore: unnecessary_null_comparison
      if (entityName == null) return;

      final modelName = modelNode.name.lexeme;

      final existingMethod = modelNode.members
          .whereType<MethodDeclaration>()
          .firstWhereOrNull((m) => m.name.lexeme == 'toEntity');

      final message = existingMethod != null
          ? 'Correct `toEntity()` method in `$modelName`'
          : 'Create `toEntity()` method in `$modelName`';

      reporter
          .createChangeBuilder(message: message, priority: 90)
          .addDartFileEdit((builder) {
        final method = buildToEntityMethod(
          modelNode: modelNode,
          entityElement: entityElement,
          entityName: entityName,
        );

        final emitter = cb.DartEmitter(useNullSafetySyntax: true);
        final rawCode = method.accept(emitter).toString();

        final formattedBlock = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format(rawCode);

        if (existingMethod != null) {
          builder.addReplacement(
            SourceRange(existingMethod.offset, existingMethod.length),
                (editBuilder) => editBuilder.write(formattedBlock),
          );
        } else {
          final insertionOffset = modelNode.rightBracket.offset;
          builder.addInsertion(insertionOffset, (editBuilder) {
            editBuilder.writeln();
            final lines = formattedBlock.split('\n');
            for (var i = 0; i < lines.length; i++) {
              final line = lines[i];
              if (line.trim().isNotEmpty) editBuilder.write('  $line');
              if (i < lines.length - 1) editBuilder.writeln();
            }
          });
        }
      });
    });
  }

  /// Builds the `toEntity` method using code_builder.
  /// Public static to allow unit testing without full resolver context.
  static cb.Method buildToEntityMethod({
    required ClassDeclaration modelNode,
    required InterfaceElement entityElement,
    required String entityName,
  }) {
    // Gather all available fields/getters in the Model
    final modelFieldNames = modelNode.members
        .whereType<FieldDeclaration>()
        .expand((f) => f.fields.variables)
        .map((v) => v.name.lexeme)
        .toSet()
      ..addAll(
        modelNode.members
            .whereType<MethodDeclaration>()
            .where((m) => m.isGetter)
            .map((m) => m.name.lexeme),
      );

    final positionalArgs = <cb.Expression>[];
    final namedArgs = <String, cb.Expression>{};

    final constructor = entityElement.unnamedConstructor;

    if (constructor != null) {
      for (final param in constructor.formalParameters) {
        final paramName = param.name;

        // Handle missing/unknown parameters gracefully
        // ignore: unnecessary_null_comparison
        if (paramName == null) continue;

        // If model has a matching field, use it. Otherwise, throw error placeholder.
        final mapping = modelFieldNames.contains(paramName)
            ? cb.refer(paramName)
            : cb.refer("throw UnimplementedError('TODO: Map field \"$paramName\"')");

        if (param.isNamed) {
          namedArgs[paramName] = mapping;
        } else {
          positionalArgs.add(mapping);
        }
      }
    }

    final body = SyntaxBuilder.call(
      cb.refer(entityName),
      positional: positionalArgs,
      named: namedArgs,
    ).returned.statement;

    return SyntaxBuilder.method(
      name: 'toEntity',
      returns: cb.refer(entityName),
      body: body,
      annotations: [cb.refer('override')],
    );
  }
}