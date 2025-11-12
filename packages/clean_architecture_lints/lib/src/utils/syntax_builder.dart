import 'package:code_builder/code_builder.dart' as cb;

class SyntaxBuilder {
  const SyntaxBuilder._();

  static cb.Library library({
    List<cb.Spec> body = const [],
    List<cb.Directive> directives = const [],
  }) {
    return cb.Library((b) => b
      ..body.addAll(body)
      ..directives.addAll(directives));
  }

  static cb.Class class$({
    required String name,
    cb.Reference? extend,
    List<cb.Reference>? implements,
    List<cb.Reference>? mixins,
    List<cb.Expression>? annotations,
    List<cb.Constructor>? constructors,
    List<cb.Field>? fields,
    List<cb.Method>? methods,
    bool isFinal = false,
  }) =>
      cb.Class((b) => b
        ..name = name
        ..annotations.addAll(annotations ?? [])
        ..extend = extend
        ..implements.addAll(implements ?? [])
        ..mixins.addAll(mixins ?? [])
        ..fields.addAll(fields ?? [])
        ..constructors.addAll(constructors ?? [])
        ..methods.addAll(methods ?? [])
        ..modifier = isFinal ? cb.ClassModifier.final$ : null);

  // --- FIX #1: Correctly handle nullable FieldModifier ---
  static cb.Field field({
    required String name,
    cb.Reference? type,
    cb.FieldModifier? modifier, // Input is correctly nullable
    bool isStatic = false,
    bool isLate = false,
    cb.Code? assignment,
    List<cb.Expression>? annotations,
  }) {
    return cb.Field((b) {
      b
        ..name = name
        ..type = type
        ..static = isStatic
        ..assignment = assignment
        ..annotations.addAll(annotations ?? [])
        ..late = isLate;
      // Only assign the modifier if it's not null.
      if (modifier != null) {
        b.modifier = modifier;
      }
    });
  }

  static cb.Constructor constructor({
    List<cb.Parameter> requiredParameters = const [],
    List<cb.Parameter> optionalParameters = const [],
    List<cb.Code> initializers = const [],
    cb.Code? body,
    bool constant = false,
    String? name,
  }) =>
      cb.Constructor((b) => b
        ..requiredParameters.addAll(requiredParameters)
        ..optionalParameters.addAll(optionalParameters)
        ..initializers.addAll(initializers)
        ..body = body
        ..constant = constant
        ..name = name);

  static cb.Method method({
    required String name,
    cb.Reference? returns,
    cb.MethodType? type,
    cb.MethodModifier? modifier,
    cb.Code? body,
    bool isLambda = false,
    List<cb.Parameter> requiredParameters = const [],
    List<cb.Parameter> optionalParameters = const [],
    List<cb.Expression> annotations = const [],
  }) =>
      cb.Method((b) => b
        ..name = name
        ..returns = returns
        ..type = type
        ..modifier = modifier
        ..body = body
        ..lambda = isLambda
        ..requiredParameters.addAll(requiredParameters)
        ..optionalParameters.addAll(optionalParameters)
        ..annotations.addAll(annotations));

  static cb.Parameter parameter({
    required String name,
    cb.Reference? type,
    bool toThis = false,
    bool isNamed = false,
    bool isRequired = false,
    cb.Code? defaultTo,
  }) =>
      cb.Parameter((b) => b
        ..name = name
        ..type = type
        ..toThis = toThis
        ..named = isNamed
        ..required = isRequired
        ..defaultTo = defaultTo);

  // --- FIX #2: Correctly type the 'definition' parameter ---
  static cb.TypeDef typeDef({
    required String name,
    required cb.Expression definition, // Changed from Spec to Expression
  }) =>
      cb.TypeDef((b) => b
        ..name = name
        ..definition = definition);

  static cb.RecordType recordType({
    Map<String, cb.Reference> namedFields = const {},
    List<cb.Reference> positionalFields = const [],
  }) =>
      cb.RecordType((b) => b
        ..namedFieldTypes.addAll(namedFields)
        ..positionalFieldTypes.addAll(positionalFields));

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
    // ... (This method remains correct)
    final useCaseClass = class$(
      name: useCaseName,
      isFinal: true,
      implements: [
        cb.TypeReference((b) => b
          ..symbol = baseClassName.symbol
          ..types.addAll(genericTypes))
      ],
      annotations: annotations,
      fields: [
        field(
          name: 'repository',
          modifier: cb.FieldModifier.final$,
          type: cb.refer(repoClassName),
        ),
      ],
      constructors: [
        constructor(
          constant: true,
          requiredParameters: [parameter(name: 'repository', toThis: true)],
        ),
      ],
      methods: [
        method(
          name: 'call',
          isLambda: true,
          returns: returnType,
          requiredParameters: callParams,
          annotations: [cb.refer('override')],
          body: cb
              .refer('repository')
              .property(methodName)
              .call(repoCallPositionalArgs, repoCallNamedArgs)
              .code,
        ),
      ],
    );

    return [useCaseClass];
  }

  static cb.Expression call(
      cb.Expression callee, {
        List<cb.Expression> positional = const [],
        Map<String, cb.Expression> named = const {},
      }) {
    return callee.call(positional, named);
  }
}
