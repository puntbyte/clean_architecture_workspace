// lib/src/utils/syntax_builder.dart

import 'package:code_builder/code_builder.dart';

// Your brilliant SyntaxBuilder class, almost verbatim.
class SyntaxBuilder {
  const SyntaxBuilder._();

  static Library library({List<Spec> elements = const [], List<Directive> directives = const []}) {
    return Library((builder) {
      builder.body.addAll(elements);
      builder.directives.addAll(directives);
    });
  }

  static Class class$({
    required String name,
    Reference? extend,
    List<Reference>? implements,
    List<Reference>? mixins,
    List<Expression>? annotations,
    List<Constructor>? constructors,
    List<Field>? fields,
    List<Method>? methods,
    bool isFinal = false,
  }) => Class(
    (builder) => builder
      ..name = name
      ..annotations.addAll(annotations ?? [])
      ..extend = extend
      ..implements.addAll(implements ?? [])
      ..mixins.addAll(mixins ?? [])
      ..fields.addAll(fields ?? [])
      ..constructors.addAll(constructors ?? [])
      ..methods.addAll(methods ?? [])
      ..modifier = isFinal ? ClassModifier.final$ : null,
  );

  static Field field({
    required String name,
    Reference? type,
    FieldModifier? modifier,
    bool isStatic = false,
    bool isLate = false,
    Code? assignment,
    List<Expression>? annotations,
  }) => Field((builder) {
    builder
      ..name = name
      ..type = type
      ..static = isStatic
      ..assignment = assignment
      ..annotations.addAll(annotations ?? [])
      ..late = isLate;
    if (modifier != null) builder.modifier = modifier;
  });

  // CORRECTION: Your constructor had a slight issue with handling lists vs. single items.
  // This version is more robust.
  static Constructor constructor({
    List<Parameter> requiredParameters = const [],
    List<Parameter> optionalParameters = const [],
    List<Code> initializers = const [],
    Code? body,
    bool constant = false,
    String? name,
  }) => Constructor(
    (builder) => builder
      ..requiredParameters.addAll(requiredParameters)
      ..optionalParameters.addAll(optionalParameters)
      ..initializers.addAll(initializers)
      ..body = body
      ..constant = constant
      ..name = name,
  );

  static Method method({
    required String name,
    Reference? returns,
    MethodType? type,
    MethodModifier? modifier,
    Code? body,
    bool isLambda = false,
    List<Parameter> requiredParameters = const [],
    List<Parameter> optionalParameters = const [],
    List<Expression> annotations = const [],
  }) => Method(
    (builder) => builder
      ..name = name
      ..returns = returns
      ..type = type
      ..modifier = modifier
      ..body = body
      ..lambda = isLambda
      ..requiredParameters.addAll(requiredParameters)
      ..optionalParameters.addAll(optionalParameters)
      ..annotations.addAll(annotations),
  );

  static Parameter parameter({
    required String name,
    Reference? type,
    bool toThis = false,
    bool isNamed = false,
    bool isRequired = false,
    Code? defaultTo,
  }) => Parameter(
    (builder) => builder
      ..name = name
      ..type = type
      ..toThis = toThis
      ..named = isNamed
      ..required = isRequired
      ..defaultTo = defaultTo,
  );
}
