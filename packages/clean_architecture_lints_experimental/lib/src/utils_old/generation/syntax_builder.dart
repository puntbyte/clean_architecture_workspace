// lib/src/utils/generation/syntax_builder.dart

import 'package:code_builder/code_builder.dart' as cb;

/// A declarative wrapper around the `code_builder` API to simplify and
/// standardize the generation of Dart code.
class SyntaxBuilder {
  const SyntaxBuilder._();

  /// Builds a [cb.Library] spec.
  static cb.Library library({List<cb.Spec> body = const []}) {
    return cb.Library((b) => b.body.addAll(body));
  }

  /// Builds a [cb.TypeDef] spec, typically used for defining record type aliases.
  ///
  /// Example: `typedef MyParams = ({int id});`
  static cb.TypeDef typeDef({required String name, required cb.Expression definition}) {
    return cb.TypeDef(
      (b) => b
        ..name = name
        ..definition = definition,
    );
  }

  /// Builds a [cb.RecordType] spec.
  ///
  /// Example: `({String name, int id})`
  static cb.RecordType recordType({Map<String, cb.Reference> namedFields = const {}}) {
    return cb.RecordType((b) => b.namedFieldTypes.addAll(namedFields));
  }

  /// Builds a [cb.Parameter] spec for a method or constructor.
  static cb.Parameter parameter({
    required String name,
    cb.Reference? type,
    bool toThis = false,
    bool isNamed = false,
    bool isRequired = false,
  }) {
    return cb.Parameter(
      (b) => b
        ..name = name
        ..type = type
        ..toThis = toThis
        ..named = isNamed
        ..required = isRequired,
    );
  }

  /// Builds a method or function invocation expression [cb.InvokeExpression].
  static cb.Expression call(
    cb.Expression callee, {
    List<cb.Expression> positional = const [],
    Map<String, cb.Expression> named = const {},
  }) {
    return callee.call(positional, named);
  }

  /// Builds a [cb.Field] spec.
  static cb.Field field({
    required String name,
    cb.Reference? type,
    cb.FieldModifier? modifier,
    cb.Code? assignment,
    List<cb.Expression>? annotations,
  }) {
    return cb.Field((b) {
      b
        ..name = name
        ..type = type
        ..assignment = assignment
        ..annotations.addAll(annotations ?? []);
      if (modifier != null) {
        b.modifier = modifier;
      }
    });
  }

  /// Builds a [cb.Constructor] spec.
  static cb.Constructor constructor({
    List<cb.Parameter> requiredParameters = const [],
    List<cb.Parameter> optionalParameters = const [],
    List<cb.Code> initializers = const [],
    cb.Code? body,
    bool constant = false,
  }) {
    return cb.Constructor(
      (b) => b
        ..requiredParameters.addAll(requiredParameters)
        ..optionalParameters.addAll(optionalParameters)
        ..initializers.addAll(initializers)
        ..body = body
        ..constant = constant,
    );
  }

  /// Builds a [cb.Method] spec. Defaults to a `void` return type and an
  /// empty block body `{}` if not specified.
  static cb.Method method({
    required String name,
    cb.Reference? returns,
    cb.Code? body,
    bool isLambda = false,
    List<cb.Parameter> requiredParameters = const [],
    List<cb.Expression> annotations = const [],
  }) {
    return cb.Method(
      (b) => b
        ..name = name
        ..returns = returns ?? cb.refer('void')
        ..requiredParameters.addAll(requiredParameters)
        ..annotations.addAll(annotations)
        ..lambda = isLambda
        // Provide an empty block as a safe default for non-lambda methods.
        ..body = body ?? (isLambda ? null : cb.Block.of([])),
    );
  }

  /// High-level builder for a complete UseCase class.
  static List<cb.Spec> useCase({
    required String useCaseName,
    required String repoClassName,
    required String methodName,
    required cb.Reference returnType,
    required cb.Reference baseClassName,
    required List<cb.Reference> genericTypes,
    required List<cb.Parameter> callParams,
    required List<cb.Expression> repoCallPositionalArgs,
    required Map<String, cb.Expression> repoCallNamedArgs,
    required List<cb.Expression> annotations,
  }) {
    return [
      cb.Class(
        (b) => b
          ..name = useCaseName
          ..modifier = cb.ClassModifier.final$
          ..implements.add(
            cb.TypeReference(
              (b) => b
                ..symbol = baseClassName.symbol
                ..url = baseClassName.url
                ..types.addAll(genericTypes),
            ),
          )
          ..annotations.addAll(annotations)
          ..fields.add(
            field(
              name: '_repository',
              modifier: cb.FieldModifier.final$,
              type: cb.refer(repoClassName),
            ),
          )
          ..constructors.add(
            constructor(
              constant: true,
              requiredParameters: [parameter(name: '_repository', toThis: true)],
            ),
          )
          ..methods.add(
            method(
              name: 'call',
              returns: returnType,
              requiredParameters: callParams,
              annotations: [cb.refer('override')],
              isLambda: true,
              body: call(
                cb.refer('_repository').property(methodName),
                positional: repoCallPositionalArgs,
                named: repoCallNamedArgs,
              ).code,
            ),
          ),
      ),
    ];
  }
}
