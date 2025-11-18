// lib/src/fixes/create_use_case_fix.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';

// Intentionally imported (still common in plugin code)
// ignore: implementation_imports
import 'package:analyzer/src/dart/ast/utilities.dart' show NodeLocator2;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/iterable_extension.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:clean_architecture_lints/src/utils/path_utils.dart';
import 'package:clean_architecture_lints/src/utils/syntax_builder.dart';
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
      final node = NodeLocator2(diagnostic.offset).searchWithin(resolvedUnit.unit);
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
          // Use named parameter `customPath` to write to a new file path.
          .addDartFileEdit(
            (DartFileEditBuilder builder) {
              final library = _buildUseCaseLibrary(method: methodNode, repoNode: repoNode);
              _addImports(
                builder: builder,
                method: methodNode,
                repoNode: repoNode,
                context: context,
              );

              final emitter = cb.DartEmitter();
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
      // use config to derive names if available
      unaryName:
          config.inheritances
              .ruleFor(ArchComponent.usecase.id)
              ?.required
              .firstWhereOrNull((d) => d.name.contains('Unary'))
              ?.name ??
          'UnaryUsecase',
      nullaryName:
          config.inheritances
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

  /// Public — made testable.
  ///
  /// This is robust both for resolved ASTs (where `declaredElement` is present)
  /// and for unresolved ASTs (where we fallback to reading the type/name from the AST).
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

      // Prefer resolved element when available
      final paramElement = _getParameterElement(param);
      if (paramElement != null && paramElement.name != null) {
        final paramType = cb.refer(
          paramElement.type.getDisplayString(),
        ); // DartType.getDisplayString exists
        final paramName = paramElement.name!;
        final isPositional = paramElement.isPositional && !paramElement.isOptionalPositional;
        final isNamed = paramElement.isNamed;

        return UseCaseGenerationConfig(
          baseClassName: cb.refer(unaryName),
          genericTypes: [outputType, paramType],
          callParams: [SyntaxBuilder.parameter(name: paramName, type: paramType)],
          repoCallPositionalArgs: isPositional ? [cb.refer(paramName)] : [],
          repoCallNamedArgs: isNamed ? {paramName: cb.refer(paramName)} : {},
        );
      }

      // Fallback: extract info from AST for unresolved units
      final astInfo = _extractParamFromAst(param);
      if (astInfo.name == null) {
        return UseCaseGenerationConfig.empty(nullaryName, outputType);
      }

      final paramType = cb.refer(astInfo.type ?? 'dynamic');
      final paramName = astInfo.name!;
      final isNamed = astInfo.isNamed;
      final isOptionalPositional = astInfo.isOptionalPositional;
      final isPositional = !isNamed;

      return UseCaseGenerationConfig(
        baseClassName: cb.refer(unaryName),
        genericTypes: [outputType, paramType],
        callParams: [SyntaxBuilder.parameter(name: paramName, type: paramType)],
        repoCallPositionalArgs: (isPositional && !isOptionalPositional)
            ? [cb.refer(paramName)]
            : [],
        repoCallNamedArgs: isNamed ? {paramName: cb.refer(paramName)} : {},
      );
    }

    // multi params -> record param wrapper
    final useCaseNamePascal = methodName.toPascalCase();
    final recordName = '_${useCaseNamePascal}Params';
    final recordRef = cb.refer(recordName);

    final recordFields = <String, cb.Reference>{};
    final repoCallArgs = <String, cb.Expression>{};
    for (final p in params) {
      final element = _getParameterElement(p);
      if (element != null && element.name != null) {
        final name = element.name!;

        recordFields[name] = cb.refer(element.runtimeType.toString());
        repoCallArgs[name] = cb.refer('params').property(name);
        continue;
      }

      // fallback from AST
      final astInfo = _extractParamFromAst(p);
      if (astInfo.name == null) continue;
      final name = astInfo.name!;
      recordFields[name] = cb.refer(astInfo.type ?? 'dynamic');
      repoCallArgs[name] = cb.refer('params').property(name);
    }

    final recordTypeDef = SyntaxBuilder.typeDef(
      name: recordName,
      definition: SyntaxBuilder.recordType(namedFields: recordFields),
    );
    return UseCaseGenerationConfig(
      baseClassName: cb.refer(unaryName),
      genericTypes: [outputType, recordRef],
      callParams: [SyntaxBuilder.parameter(name: 'params', type: recordRef)],
      repoCallNamedArgs: repoCallArgs,
      recordTypeDef: recordTypeDef,
    );
  }

  // Replace the old helper with this:
  static FormalParameterElement? _getParameterElement(FormalParameter param) {
    // Unwrap DefaultFormalParameter to get the inner normalized node
    final actual = param is DefaultFormalParameter ? param.parameter : param;

    // Try fragment-based element (analyzer 8.x)
    final fragment = actual.declaredFragment;
    if (fragment != null) {
      final elem = fragment.element;
      return elem;
    }

    // No resolved element available
    return null;
  }

  static _AstParamInfo _extractParamFromAst(FormalParameter param) {
    final actual = param is DefaultFormalParameter ? param.parameter : param;

    final name = actual.name?.lexeme;
    String? typeSource;

    if (actual is SimpleFormalParameter) {
      typeSource = actual.type?.toSource();
    } else if (actual is FieldFormalParameter) {
      typeSource = actual.type?.toSource();
    } else if (actual is FunctionTypedFormalParameter) {
      typeSource = actual.returnType?.toSource();
    }

    final isNamed = param.isNamed;
    final isOptionalPositional = param.isOptionalPositional;

    return _AstParamInfo(
      name: name,
      type: typeSource,
      isNamed: isNamed,
      isOptionalPositional: isOptionalPositional,
    );
  }

  void _addImports({
    required DartFileEditBuilder builder,
    required MethodDeclaration method,
    required ClassDeclaration repoNode,
    required CustomLintContext context,
  }) {
    final importedUris = <String>{};
    void importLibraryChecked(Uri uri) {
      if (uri.isScheme('dart')) return;
      if (importedUris.add(uri.toString())) {
        builder.importLibrary(uri);
      }
    }

    final repoLibrary = repoNode.declaredFragment?.libraryFragment.element;
    if (repoLibrary != null) {
      final src = repoLibrary.firstFragment.source;
      importLibraryChecked(src.uri);
    }

    config.annotations.ruleFor(ArchComponent.usecase.id)?.required.forEach((detail) {
      if (detail.import != null) importLibraryChecked(Uri.parse(detail.import!));
    });
    config.inheritances.ruleFor(ArchComponent.usecase.id)?.required.forEach((detail) {
      if (detail.import.isNotEmpty) importLibraryChecked(Uri.parse(detail.import));
    });

    for (final rule in config.typeSafeties.rules) {
      for (final detail in rule.returns) {
        if (detail.import != null) importLibraryChecked(Uri.parse(detail.import!));
      }
      for (final detail in rule.parameters) {
        if (detail.import != null) importLibraryChecked(Uri.parse(detail.import!));
      }
    }

    _importType(method.returnType?.type, importLibraryChecked);
    for (final param in method.parameters?.parameters ?? <FormalParameter>[]) {
      _importType(_getParameterElement(param)?.type, importLibraryChecked);
    }
  }

  void _importType(DartType? type, void Function(Uri) importLibrary) {
    if (type == null || (type.element?.library?.isInSdk ?? false)) return;

    final source = type.element?.library?.firstFragment.source;
    if (source != null) {
      importLibrary(source.uri);
    }
    if (type is InterfaceType) {
      for (final arg in type.typeArguments) {
        _importType(arg, importLibrary);
      }
    }
  }

  cb.Reference extractOutputType(DartType? returnType) {
    if (returnType is! InterfaceType) return cb.refer('void');
    final futureArg = returnType.typeArguments.isNotEmpty ? returnType.typeArguments.first : null;
    if (futureArg is! InterfaceType) return cb.refer('void');
    final successArg = futureArg.typeArguments.isNotEmpty ? futureArg.typeArguments.last : null;
    return cb.refer(successArg?.getDisplayString() ?? 'void');
  }
}

/// Public config returned from the parameter builder.
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

  UseCaseGenerationConfig.empty(String nullaryName, cb.Reference outputType)
    : this(baseClassName: cb.refer(nullaryName), genericTypes: [outputType], callParams: []);
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
