// lib/src/fixes/create_use_case_fix.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:clean_architecture_lints/src/utils/file/path_utils.dart';
import 'package:clean_architecture_lints/src/utils/codegen/syntax_builder.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:dart_style/dart_style.dart';

class CreateUseCaseFix extends DartFix {
  final ArchitectureConfig config;

  CreateUseCaseFix({required this.config});

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

      final methodNode = node?.thisOrAncestorOfType<MethodDeclaration>();
      if (methodNode == null) return;

      final repoNode = methodNode.thisOrAncestorOfType<ClassDeclaration>();
      if (repoNode == null) return;

      final useCaseFilePath = PathUtils.getUseCaseFilePath(
        methodName: methodNode.name.lexeme,
        repoPath: diagnostic.source.fullName,
        config: config,
      );
      if (useCaseFilePath == null) return;

      reporter
          .createChangeBuilder(
        message: 'Create UseCase for `${methodNode.name.lexeme}`',
        priority: 90,
      )
          .addDartFileEdit(
            (DartFileEditBuilder builder) {
          final library = _buildUseCaseLibrary(method: methodNode, repoNode: repoNode);
          _addImports(
            builder: builder,
            method: methodNode,
            repoNode: repoNode,
          );

          final emitter = cb.DartEmitter(useNullSafetySyntax: true);
          final raw = library.accept(emitter).toString();

          final formattedCode = DartFormatter(
            languageVersion: DartFormatter.latestLanguageVersion,
          ).format(raw);

          builder.addInsertion(
            0,
                (EditBuilder editBuilder) => editBuilder.write(formattedCode),
          );
        },
        customPath: useCaseFilePath,
      );
    });
  }

  cb.Library _buildUseCaseLibrary({
    required MethodDeclaration method,
    required ClassDeclaration repoNode,
  }) {
    final bodyElements = <cb.Spec>[];
    final methodName = method.name.lexeme;
    final returnType = method.returnType?.type;
    final returnTypeRef = cb.refer(returnType?.getDisplayString() ?? 'void');
    final outputType = extractOutputType(returnType);

    final paramConfig = buildParameterConfigFromParams(
      params: method.parameters?.parameters ?? [],
      methodName: methodName,
      outputType: outputType,
      unaryName: config.inheritances
          .ruleFor(ArchComponent.usecase.id)
          ?.required
          .firstWhereOrNull((d) => d.name.contains('Unary'))
          ?.name ??
          'UnaryUsecase',
      nullaryName: config.inheritances
          .ruleFor(ArchComponent.usecase.id)
          ?.required
          .firstWhereOrNull((d) => d.name.contains('Nullary'))
          ?.name ??
          'NullaryUsecase',
    );

    if (paramConfig.recordTypeDef != null) {
      bodyElements.add(paramConfig.recordTypeDef!);
    }

    final annotationRule = config.annotations.ruleFor(ArchComponent.usecase.id);
    final annotations =
        annotationRule?.required.map((a) => cb.refer(a.name).call([])).toList() ?? [];

    final useCaseName = NamingUtils.getExpectedUseCaseClassName(methodName, config);

    bodyElements.addAll(
      SyntaxBuilder.useCase(
        useCaseName: useCaseName,
        repoClassName: repoNode.name.lexeme,
        methodName: methodName,
        returnType: returnTypeRef,
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

  static UseCaseGenerationConfig buildParameterConfigFromParams({
    required List<FormalParameter> params,
    required String methodName,
    required cb.Reference outputType,
    required String unaryName,
    required String nullaryName,
  }) {
    if (params.isEmpty) {
      return UseCaseGenerationConfig(
        baseClassName: cb.refer(nullaryName),
        genericTypes: [outputType],
        callParams: [],
      );
    }

    if (params.length == 1) {
      final param = params.first;
      final astInfo = _extractParamFromAst(param);

      if (astInfo.name == null) {
        // Fallback if something is terribly wrong with AST
        return UseCaseGenerationConfig(
            baseClassName: cb.refer(nullaryName),
            genericTypes: [outputType],
            callParams: []
        );
      }

      final paramType = cb.refer(astInfo.type ?? 'dynamic');
      final paramName = astInfo.name!;
      final isNamed = astInfo.isNamed;

      // For optional positional ([int? id]), we treat it as a single param for the Unary case.
      final isPositional = !isNamed;

      return UseCaseGenerationConfig(
        baseClassName: cb.refer(unaryName),
        genericTypes: [outputType, paramType],
        callParams: [SyntaxBuilder.parameter(name: paramName, type: paramType)],
        // If it's positional (even optional), we pass it as positional to repo.
        repoCallPositionalArgs: isPositional ? [cb.refer(paramName)] : [],
        // If named, pass as named.
        repoCallNamedArgs: isNamed ? {paramName: cb.refer(paramName)} : {},
      );
    }

    // Multi-params -> Generate a Record-like TypeDef wrapper
    final useCaseNamePascal = methodName.toPascalCase();
    final recordName = '_${useCaseNamePascal}Params';
    final recordRef = cb.refer(recordName);

    final recordFields = <String, cb.Reference>{};
    final repoCallArgsPositional = <cb.Expression>[];
    final repoCallArgsNamed = <String, cb.Expression>{};

    for (final p in params) {
      final astInfo = _extractParamFromAst(p);
      if (astInfo.name == null) continue;

      final name = astInfo.name!;
      recordFields[name] = cb.refer(astInfo.type ?? 'dynamic');

      final fieldRef = cb.refer('params').property(name);

      if (astInfo.isNamed) {
        repoCallArgsNamed[name] = fieldRef;
      } else {
        repoCallArgsPositional.add(fieldRef);
      }
    }

    final recordTypeDef = SyntaxBuilder.typeDef(
      name: recordName,
      definition: SyntaxBuilder.recordType(namedFields: recordFields),
    );

    return UseCaseGenerationConfig(
      baseClassName: cb.refer(unaryName),
      genericTypes: [outputType, recordRef],
      callParams: [SyntaxBuilder.parameter(name: 'params', type: recordRef)],
      repoCallPositionalArgs: repoCallArgsPositional,
      repoCallNamedArgs: repoCallArgsNamed,
      recordTypeDef: recordTypeDef,
    );
  }

  static _AstParamInfo _extractParamFromAst(FormalParameter param) {
    final actual = param is DefaultFormalParameter ? param.parameter : param;
    final name = actual.name?.lexeme;

    String? typeSource;
    // Use resolved element if available for better type strings
    if (actual.declaredFragment?.element.type != null) {
      typeSource = actual.declaredFragment!.element.type.getDisplayString();
    } else {
      // Fallback to AST source if resolution is partial
      if (actual is SimpleFormalParameter) {
        typeSource = actual.type?.toSource();
      } else if (actual is FieldFormalParameter) {
        typeSource = actual.type?.toSource();
      }
    }

    return _AstParamInfo(
      name: name,
      type: typeSource,
      isNamed: param.isNamed,
      isOptionalPositional: param.isOptionalPositional,
    );
  }

  void _addImports({
    required DartFileEditBuilder builder,
    required MethodDeclaration method,
    required ClassDeclaration repoNode,
  }) {
    final importedUris = <String>{};

    void importChecked(Uri uri) {
      if (uri.isScheme('dart')) return;
      if (importedUris.add(uri.toString())) {
        builder.importLibrary(uri);
      }
    }

    // Import the Repository definition
    final repoLibrary = repoNode.declaredFragment?.element.library;
    if (repoLibrary != null) {
      importChecked(repoLibrary.firstFragment.source.uri);
    }

    // Import Annotations (e.g. Injectable)
    config.annotations.ruleFor(ArchComponent.usecase.id)?.required.forEach((detail) {
      if (detail.import != null) importChecked(Uri.parse(detail.import!));
    });

    // Import Base UseCase Classes
    config.inheritances.ruleFor(ArchComponent.usecase.id)?.required.forEach((detail) {
      importChecked(Uri.parse(detail.import));
    });

    // Import Type Safety Types (e.g. FutureEither, Failure)
    for (final rule in config.typeSafeties.rules) {
      for (final detail in rule.returns) {
        if (detail.import != null) importChecked(Uri.parse(detail.import!));
      }
    }

    // Helper to import types found in method signature
    void importType(DartType? type) {
      if (type == null || (type.element?.library?.isInSdk ?? false)) return;
      final source = type.element?.library?.firstFragment.source;
      if (source != null) importChecked(source.uri);

      if (type is InterfaceType) {
        for (final arg in type.typeArguments) importType(arg);
      }
    }

    importType(method.returnType?.type);
    for (final param in method.parameters?.parameters ?? <FormalParameter>[]) {
      // Try to resolve param type
      final paramEl = param.declaredFragment?.element;
      if (paramEl != null) importType(paramEl.type);
    }
  }

  cb.Reference extractOutputType(DartType? returnType) {
    if (returnType is! InterfaceType) return cb.refer('void');

    // Handle Future<T>
    if (returnType.isDartAsyncFuture || returnType.isDartAsyncFutureOr) {
      final inner = returnType.typeArguments.firstOrNull;
      if (inner is InterfaceType) {
        // Handle Future<Either<L, R>> -> Extract R
        // Assuming standard Either where R is the last arg.
        if (inner.typeArguments.isNotEmpty) {
          // Heuristic: Last generic arg is usually the success type
          return cb.refer(inner.typeArguments.last.getDisplayString());
        }
        return cb.refer(inner.getDisplayString());
      }
      return cb.refer(inner?.getDisplayString() ?? 'void');
    }

    return cb.refer(returnType.getDisplayString());
  }
}

class UseCaseGenerationConfig {
  final cb.Reference baseClassName;
  final List<cb.Reference> genericTypes;
  final List<cb.Parameter> callParams;
  final List<cb.Expression> repoCallPositionalArgs;
  final Map<String, cb.Expression> repoCallNamedArgs;
  final cb.TypeDef? recordTypeDef;

  UseCaseGenerationConfig({
    required this.baseClassName,
    required this.genericTypes,
    required this.callParams,
    this.repoCallPositionalArgs = const [],
    this.repoCallNamedArgs = const {},
    this.recordTypeDef,
  });
}

class _AstParamInfo {
  final String? name;
  final String? type;
  final bool isNamed;
  final bool isOptionalPositional;

  _AstParamInfo({
    required this.name,
    required this.type,
    required this.isNamed,
    required this.isOptionalPositional,
  });
}