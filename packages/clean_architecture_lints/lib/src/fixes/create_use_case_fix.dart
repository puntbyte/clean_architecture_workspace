// lib/src/fixes/create_use_case_fix.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/configs/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/file/path_utils.dart';
import 'package:clean_architecture_lints/src/utils/generation/syntax_builder.dart';
import 'package:clean_architecture_lints/src/utils/nlp/naming_utils.dart';
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
      final resourceProvider = resolvedUnit.session.resourceProvider;

      // [Analyzer 8.0.0] Use nodeCovering
      final node = resolvedUnit.unit.nodeCovering(offset: diagnostic.offset);

      final methodNode = node?.thisOrAncestorOfType<MethodDeclaration>();
      if (methodNode == null) return;

      final repoNode = methodNode.thisOrAncestorOfType<ClassDeclaration>();
      if (repoNode == null) return;

      final useCaseFilePath = PathUtils.getUseCaseFilePath(
        methodName: methodNode.name.lexeme,
        repoPath: diagnostic.source.fullName,
        config: config,
        resourceProvider: resourceProvider,
      );
      if (useCaseFilePath == null) return;

      reporter
          .createChangeBuilder(
            message: 'Create UseCase for `${methodNode.name.lexeme}`',
            priority: 90,
          )
          .addDartFileEdit(
            (DartFileEditBuilder builder) {
              final imports = _collectImports(method: methodNode, repoNode: repoNode);

              final library = _buildUseCaseLibrary(
                method: methodNode,
                repoNode: repoNode,
                imports: imports,
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
    required Set<String> imports,
  }) {
    final directives = imports.map(cb.Directive.import).toList()
      ..sort((a, b) => a.url.compareTo(b.url));

    final bodyElements = <cb.Spec>[];
    final methodName = method.name.lexeme;
    final returnType = method.returnType?.type;
    final returnTypeRef = cb.refer(returnType?.getDisplayString() ?? 'void');
    final outputType = extractOutputType(returnType);

    final rules = config.inheritances.ruleFor(ArchComponent.usecase.id)?.required ?? [];

    final configuredUnary = rules.firstWhereOrNull((d) => d.name?.contains('Unary') ?? false)?.name;

    final configuredNullary = rules
        .firstWhereOrNull((d) => d.name?.contains('Nullary') ?? false)
        ?.name;

    final paramConfig = buildParameterConfigFromParams(
      params: method.parameters?.parameters ?? [],
      methodName: methodName,
      outputType: outputType,
      unaryName: configuredUnary ?? 'UnaryUsecase',
      nullaryName: configuredNullary ?? 'NullaryUsecase',
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

    return cb.Library(
      (b) => b
        ..directives.addAll(directives)
        ..body.addAll(bodyElements),
    );
  }

  Set<String> _collectImports({
    required MethodDeclaration method,
    required ClassDeclaration repoNode,
  }) {
    final importedUris = <String>{};

    void addImport(String? uri) {
      if (uri != null && uri.isNotEmpty && !uri.startsWith('dart:core')) {
        importedUris.add(uri);
      }
    }

    // Resolves the import from type definitions config
    void addImportFromType(String typeKey) {
      final typeDef = config.typeDefinitions.get(typeKey);
      addImport(typeDef?.import);
    }

    // 1. Repository Import
    final repoLibrary = repoNode.declaredFragment?.element.library;
    addImport(repoLibrary?.firstFragment.source.uri.toString());

    // 2. Inheritance Imports
    config.inheritances.ruleFor(ArchComponent.usecase.id)?.required.forEach((d) {
      addImport(d.import);
    });

    // 3. Annotation Imports
    config.annotations.ruleFor(ArchComponent.usecase.id)?.required.forEach((d) {
      addImport(d.import);
    });

    // 4. Type Safety Imports
    for (final rule in config.typeSafeties.rules) {
      // Allowed types often require imports (e.g. Result, FutureEither)
      for (final d in rule.allowed) {
        if (d.type != null) addImportFromType(d.type!);
      }
    }

    // 5. Method Signature Imports
    void collectFromType(DartType? type) {
      if (type == null) return;
      if (type is VoidType || type is DynamicType) return;

      final element = type.element;
      if (element != null) {
        addImport(element.library?.firstFragment.source.uri.toString());
      }

      if (type is InterfaceType) type.typeArguments.forEach(collectFromType);

      if (type.alias != null) {
        final aliasElement = type.alias!.element;
        addImport(aliasElement.library.firstFragment.source.uri.toString());
        type.alias!.typeArguments.forEach(collectFromType);
      }
    }

    collectFromType(method.returnType?.type);
    for (final param in method.parameters?.parameters ?? <FormalParameter>[]) {
      collectFromType(param.declaredFragment?.element.type);
    }

    return importedUris;
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
        return UseCaseGenerationConfig(
          baseClassName: cb.refer(nullaryName),
          genericTypes: [outputType],
          callParams: [],
        );
      }

      final paramType = cb.refer(astInfo.type ?? 'dynamic');
      final paramName = astInfo.name!;
      final isNamed = astInfo.isNamed;
      final isPositional = !isNamed;

      return UseCaseGenerationConfig(
        baseClassName: cb.refer(unaryName),
        genericTypes: [outputType, paramType],
        callParams: [SyntaxBuilder.parameter(name: paramName, type: paramType)],
        repoCallPositionalArgs: isPositional ? [cb.refer(paramName)] : [],
        repoCallNamedArgs: isNamed ? {paramName: cb.refer(paramName)} : {},
      );
    }

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
    if (actual.declaredFragment?.element.type != null) {
      typeSource = actual.declaredFragment!.element.type.getDisplayString();
    } else {
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

  cb.Reference extractOutputType(DartType? returnType) {
    if (returnType is! InterfaceType) return cb.refer('void');

    if (returnType.isDartAsyncFuture || returnType.isDartAsyncFutureOr) {
      final inner = returnType.typeArguments.firstOrNull;
      if (inner is InterfaceType) {
        if (inner.typeArguments.isNotEmpty) {
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
