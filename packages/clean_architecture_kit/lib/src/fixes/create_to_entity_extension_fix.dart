import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
// Deliberate import of internal AST locator utility used by many analyzer plugins.
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_style/dart_style.dart';

class CreateToEntityExtensionFix extends Fix {
  final CleanArchitectureConfig config;

  CreateToEntityExtensionFix({required this.config});

  @override
  List<String> get filesToAnalyze => const ['**.dart'];

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
      final locator = NodeLocator2(diagnostic.problemMessage.offset);
      final modelNode = locator
          .searchWithin(resolvedUnit.unit)
          ?.thisOrAncestorOfType<ClassDeclaration>();
      if (modelNode == null) return;

      // ▼▼▼ APPLY THE SAME ROBUST FIX HERE ▼▼▼
      final entityElement = _findInheritedEntityElement(modelNode);
      if (entityElement == null) return;
      // ▲▲▲ END OF FIX ▲▲▲

      final modelName = modelNode.name.lexeme;

      final changeBuilder =
          reporter.createChangeBuilder(
            message: 'Create `toEntity()` in an extension',
            priority: 70,
          )..addDartFileEdit((builder) {
            final extension = _buildMappingExtension(
              modelNode: modelNode,
              entityElement: entityElement,
            );

            final emitter = cb.DartEmitter(useNullSafetySyntax: true);
            final unformattedCode = extension.accept(emitter).toString();
            final formattedCode = DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format(unformattedCode);

            final insertionOffset = modelNode.end;
            builder.addInsertion(insertionOffset, (editBuilder) {
              editBuilder.write('\n\n$formattedCode');
            });
          });
    });
  }

  /// Finds the ClassElement of the inherited Entity by inspecting the element model.
  ClassElement? _findInheritedEntityElement(ClassDeclaration modelNode) {
    final superclass = modelNode.extendsClause?.superclass;
    if (superclass?.element is ClassElement) {
      return superclass!.element! as ClassElement;
    }
    final interface = modelNode.implementsClause?.interfaces.firstOrNull;
    if (interface?.element is ClassElement) {
      return interface!.element! as ClassElement;
    }
    return null;
  }

  /// Builds the intelligent `toEntity()` extension.
  cb.Extension _buildMappingExtension({
    required ClassDeclaration modelNode,
    required ClassElement entityElement,
  }) {
    final modelName = modelNode.name.lexeme;
    final entityName = entityElement.name ?? entityElement.displayName;
    final mappingBody = StringBuffer()..writeln('return $entityName(');

    final modelFieldNames = modelNode.members
        .whereType<FieldDeclaration>()
        .expand((f) => f.fields.variables)
        .map((v) => v.name.lexeme)
        .toSet();

    final constructor = entityElement.unnamedConstructor;
    if (constructor != null) {
      for (final param in constructor.formalParameters) {
        if (modelFieldNames.contains(param.name)) {
          mappingBody.writeln('  ${param.name}: ${param.name},');
        } else {
          mappingBody.writeln('  // TODO: Map the `${param.name}` field.');
        }
      }
    }
    mappingBody.write(');');

    return cb.Extension(
      (b) => b
        ..name = '${modelName}Mapping'
        ..on = cb.refer(modelName)
        ..methods.add(
          cb.Method(
            (m) => m
              ..name = 'toEntity'
              ..returns = cb.refer(entityName)
              ..body = cb.Code(mappingBody.toString()),
          ),
        ),
    );
  }
}
