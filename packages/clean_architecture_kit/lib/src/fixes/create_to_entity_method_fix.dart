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

class CreateToEntityMethodFix extends Fix {
  final CleanArchitectureConfig config;

  CreateToEntityMethodFix({required this.config});

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

      final entityElement = _findInheritedEntityElement(modelNode);
      if (entityElement == null) return;

      final entityName = entityElement.name;
      if (entityName == null) return; // Cannot create a fix for an unnamed entity.

      final modelName = modelNode.name.lexeme;

      reporter.createChangeBuilder(
        message: 'Create `toEntity()` method in `$modelName`',
        priority: 90,
      ).addDartFileEdit((builder) {
        final method = _buildToEntityMethod(
          modelNode: modelNode,
          entityElement: entityElement,
          entityName: entityName, // Pass the non-null name
        );

        final emitter = cb.DartEmitter(useNullSafetySyntax: true);
        final unformattedCode = method.accept(emitter).toString();
        final formattedCode = DartFormatter(
          languageVersion: DartFormatter.latestLanguageVersion,
        ).format(unformattedCode);

        final insertionOffset = modelNode.rightBracket.offset;
        builder.addInsertion(insertionOffset, (editBuilder) {
          editBuilder
            ..write('\n')
            ..writeIndent()
            ..write(formattedCode);
        });
      });
    });
  }

  ClassElement? _findInheritedEntityElement(ClassDeclaration modelNode) {
    final superclass = modelNode.extendsClause?.superclass;
    if (superclass?.element is ClassElement) return superclass!.element! as ClassElement;

    final interface = modelNode.implementsClause?.interfaces.firstOrNull;
    if (interface?.element is ClassElement) return interface!.element! as ClassElement;

    return null;
  }

  cb.Method _buildToEntityMethod({
    required ClassDeclaration modelNode,
    required ClassElement entityElement,
    required String entityName, // Receive the non-null name
  }) {
    final mappingBody = StringBuffer()..writeln('  return $entityName(');

    final modelFieldNames = modelNode.members
        .whereType<FieldDeclaration>()
        .expand((f) => f.fields.variables)
        .map((v) => v.name.lexeme)
        .toSet();

    final constructor = entityElement.unnamedConstructor;
    if (constructor != null) {
      // The `parameters` getter is on the `ExecutableElement` interface, which
      // `ConstructorElement` implements. We can access it directly.
      for (final param in constructor.formalParameters) {
        // `param` is a `ParameterElement`. Its `name` is non-nullable.
        if (modelFieldNames.contains(param.name)) {
          mappingBody.writeln('    ${param.name}: ${param.name},');
        } else {
          final errorMessage = 'TODO: Provide a value for the "${param.name}" field.';
          mappingBody.writeln("    ${param.name}: throw UnimplementedError('$errorMessage'),");
        }
      }
    }
    mappingBody.write('  );');

    return cb.Method(
      (b) => b
        ..name = 'toEntity'
        ..returns = cb.refer(entityName)
        ..body = cb.Code(mappingBody.toString()),
    );
  }
}
