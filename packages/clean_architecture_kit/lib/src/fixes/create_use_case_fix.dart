// lib/src/fixes/create_use_case_fix.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';

//
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:clean_architecture_kit/src/utils/path_utils.dart';
import 'package:clean_architecture_kit/src/utils/syntax_builder.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_style/dart_style.dart';

/// A private data class to hold the configuration derived from method parameters.
class _UseCaseGenerationConfig {
  final cb.Reference baseClassName;
  final List<cb.Reference> genericTypes;
  final List<cb.Parameter> callParams;
  final List<cb.Expression> repoCallPositionalArgs;
  final Map<String, cb.Expression> repoCallNamedArgs;
  final cb.TypeDef? recordTypeDef;

  _UseCaseGenerationConfig({
    required this.baseClassName,
    required this.genericTypes,
    required this.callParams,
    this.repoCallPositionalArgs = const [],
    this.repoCallNamedArgs = const {},
    this.recordTypeDef,
  });
}

/// A quick fix that generates a complete UseCase file for a repository method
/// flagged by the `missing_use_case` lint.
class CreateUseCaseFix extends Fix {
  final CleanArchitectureConfig config;

  CreateUseCaseFix({required this.config});

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
      final node = locator.searchWithin(resolvedUnit.unit);
      final methodNode = node?.thisOrAncestorOfType<MethodDeclaration>();
      if (methodNode == null) return;
      final repoNode = methodNode.thisOrAncestorOfType<ClassDeclaration>();
      if (repoNode == null) return;

      final useCaseFilePath = PathUtils.getUseCaseFilePath(
        methodName: methodNode.name.lexeme,
        repoPath: diagnostic.problemMessage.filePath,
        config: config,
      );
      if (useCaseFilePath == null) return;

      reporter
          .createChangeBuilder(
            message: 'Create UseCase for `${methodNode.name.lexeme}`',
            priority: 90,
          )
          .addDartFileEdit(customPath: useCaseFilePath, (builder) {
            _addImports(builder: builder, method: methodNode, repoNode: repoNode);
            final library = _buildUseCaseLibrary(method: methodNode, repoNode: repoNode);
            final emitter = cb.DartEmitter(useNullSafetySyntax: true);
            final formattedCode = DartFormatter(
              languageVersion: DartFormatter.latestLanguageVersion,
            ).format(library.accept(emitter).toString());
            builder.addInsertion(0, (editBuilder) => editBuilder.write(formattedCode));
          });
    });
  }

  /// The main orchestrator method for building the UseCase library.
  cb.Library _buildUseCaseLibrary({
    required MethodDeclaration method,
    required ClassDeclaration repoNode,
  }) {
    final bodyElements = <cb.Spec>[];
    final methodName = method.name.lexeme;
    final returnType = cb.refer(method.returnType?.toSource() ?? 'void');
    final outputType = cb.refer(_extractOutputType(returnType.symbol!));

    final paramConfig = _buildParameterConfig(
      params: method.parameters?.parameters ?? [],
      methodName: methodName,
      outputType: outputType,
    );

    if (paramConfig.recordTypeDef != null) {
      bodyElements.add(paramConfig.recordTypeDef!);
    }

    // Get the required annotations from the central `annotations` config.
    final requiredAnnotations = config.annotations.requiredFor('use_case');
    final annotations = requiredAnnotations
        .where((a) => a.text.isNotEmpty)
        .map((a) => cb.CodeExpression(cb.Code(a.text)))
        .toList();

    final useCaseName = NamingUtils.getExpectedUseCaseClassName(methodName, config);

    bodyElements.addAll(
      SyntaxBuilder.useCase(
        useCaseName: useCaseName,
        repoClassName: repoNode.name.lexeme,
        methodName: methodName,
        returnType: returnType,
        baseClassName: paramConfig.baseClassName,
        genericTypes: paramConfig.genericTypes,
        callParams: paramConfig.callParams,
        repoCallPositionalArgs: paramConfig.repoCallPositionalArgs,
        repoCallNamedArgs: paramConfig.repoCallNamedArgs,
        annotations: annotations,
      ),
    );

    return SyntaxBuilder.library(body: bodyElements);
  }

  /// A dedicated method to handle the logic for 0, 1, or multiple parameters.
  _UseCaseGenerationConfig _buildParameterConfig({
    required List<FormalParameter> params,
    required String methodName,
    required cb.Reference outputType,
  }) {
    if (params.isEmpty) {
      return _UseCaseGenerationConfig(
        baseClassName: cb.refer(config.inheritance.nullaryUseCaseName),
        genericTypes: [outputType],
        callParams: [],
      );
    }

    if (params.length == 1) {
      final param = params.first;
      final paramType = cb.refer(param.toSource().split(' ').first);
      final paramName = param.name?.lexeme ?? 'param';
      return _UseCaseGenerationConfig(
        baseClassName: cb.refer(config.inheritance.unaryUseCaseName),
        genericTypes: [outputType, paramType],
        callParams: [SyntaxBuilder.parameter(name: paramName, type: paramType)],
        repoCallPositionalArgs: param.isPositional ? [cb.refer(paramName)] : [],
        repoCallNamedArgs: param.isNamed ? {paramName: cb.refer(paramName)} : {},
      );
    }

    final useCaseNamePascal = methodName.toPascalCase();
    final recordName = config.naming.useCaseParameter.pattern.replaceAll(
      '{{name}}',
      useCaseNamePascal,
    );
    final recordRef = cb.refer(recordName);

    final namedFields = <String, cb.Reference>{};
    final repoCallNamedArgs = <String, cb.Expression>{};

    for (final p in params) {
      final element = p.declaredFragment?.element;
      if (element == null) continue;
      final displayName = element.displayName;
      namedFields[displayName] = cb.refer(element.type.getDisplayString());
      repoCallNamedArgs[displayName] = cb.refer('params').property(displayName);
    }

    final recordTypeDef = SyntaxBuilder.typeDef(
      name: recordName,
      definition: SyntaxBuilder.recordType(namedFields: namedFields),
    );

    return _UseCaseGenerationConfig(
      baseClassName: cb.refer(config.inheritance.unaryUseCaseName),
      genericTypes: [outputType, recordRef],
      callParams: [SyntaxBuilder.parameter(name: 'params', type: recordRef)],
      repoCallNamedArgs: repoCallNamedArgs,
      recordTypeDef: recordTypeDef,
    );
  }

  /// Adds all necessary imports to the file, preventing duplicates.
  void _addImports({
    required DartFileEditBuilder builder,
    required MethodDeclaration method,
    required ClassDeclaration repoNode,
  }) {
    final importedUris = <String>{};
    void importLibraryChecked(Uri uri) {
      final uriString = uri.toString();
      if (uriString.isNotEmpty && importedUris.add(uriString)) {
        builder.importLibrary(uri);
      }
    }

    final repoLibrary = repoNode.declaredFragment?.element.library;
    if (repoLibrary != null) importLibraryChecked(repoLibrary.uri);

    // Get required annotations from the central config and add their imports.
    final requiredAnnotations = config.annotations.requiredFor('use_case');
    for (final annotation in requiredAnnotations) {
      if (annotation.import != null && annotation.import!.isNotEmpty) {
        importLibraryChecked(Uri.parse(annotation.import!));
      }
    }

    final unaryPath = config.inheritance.unaryUseCasePath;
    if (unaryPath.isNotEmpty) importLibraryChecked(Uri.parse(unaryPath));
    final nullaryPath = config.inheritance.nullaryUseCasePath;
    if (nullaryPath.isNotEmpty && nullaryPath != unaryPath) {
      importLibraryChecked(Uri.parse(nullaryPath));
    }

    for (final rule in config.typeSafety.returns) {
      if (rule.importPath != null && rule.importPath!.isNotEmpty) {
        importLibraryChecked(Uri.parse(rule.importPath!));
      }
    }

    for (final param in method.parameters?.parameters ?? <FormalParameter>[]) {
      _importType(param.declaredFragment?.element.type, importLibraryChecked);
    }
    _importType(method.returnType?.type, importLibraryChecked);
  }

  /// Recursively analyzes a type to import all necessary files.
  void _importType(DartType? type, void Function(Uri) importLibrary) {
    if (type == null) return;
    if (type is InterfaceType) {
      for (final arg in type.typeArguments) {
        _importType(arg, importLibrary);
      }
    }
    final library = type.element?.library;
    if (library != null && !library.isInSdk) {
      importLibrary(library.uri);
    }
  }

  /// Extracts the "success" type from a wrapper like Future<Either<L, R>>.
  String _extractOutputType(String returnTypeSource) {
    final regex = RegExp(r'<.*,\s*([^>]+)>|<([^>]+)>');
    final match = regex.firstMatch(returnTypeSource);
    return match?.group(2)?.trim() ?? match?.group(1)?.trim() ?? 'void';
  }
}
