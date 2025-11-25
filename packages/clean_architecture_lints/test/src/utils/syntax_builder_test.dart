// test/src/utils/syntax_builder_test.dart

import 'package:clean_architecture_lints/src/utils/generation/syntax_builder.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:dart_style/dart_style.dart';
import 'package:test/test.dart';

void main() {
  group('SyntaxBuilder', () {
    final emitter = cb.DartEmitter(useNullSafetySyntax: true);
    final formatter = DartFormatter(languageVersion: DartFormatter.latestLanguageVersion);

    void expectSpec(cb.Spec spec, String expected) {
      final actualSource = spec.accept(emitter).toString();
      expect(formatter.format(actualSource), equals(formatter.format(expected)));
    }

    test('should build a parameter with a type', () {
      final paramSpec = SyntaxBuilder.parameter(name: 'id', type: cb.refer('int'));
      final methodSpec = SyntaxBuilder.method(name: 'm', requiredParameters: [paramSpec]);
      expectSpec(methodSpec, 'void m(int id) {}');
    });

    test('should build a constructor with a "toThis" parameter', () {
      final constructorSpec = SyntaxBuilder.constructor(
        constant: true,
        requiredParameters: [SyntaxBuilder.parameter(name: '_repo', toThis: true)],
      );
      final classSpec = cb.Class((b) => b..name = 'MyClass'..constructors.add(constructorSpec));
      expectSpec(classSpec, 'class MyClass { const MyClass(this._repo); }');
    });

    test('should build a final field with a type', () {
      final fieldSpec = SyntaxBuilder.field(
        name: '_repository',
        modifier: cb.FieldModifier.final$,
        type: cb.refer('AuthRepository'),
      );
      expectSpec(fieldSpec, 'final AuthRepository _repository;');
    });

    test('should build a method with a default empty block body', () {
      final methodSpec = SyntaxBuilder.method(name: 'doNothing');
      expectSpec(methodSpec, 'void doNothing() {}');
    });

    test('should build a lambda method when placed inside a class context', () {
      // Create the method spec as before.
      final methodSpec = SyntaxBuilder.method(
        name: 'call',
        returns: cb.refer('bool'),
        isLambda: true,
        annotations: [cb.refer('override')],
        body: cb.literal(true).code,
      );

      // FIX: Wrap the method in a class to create a valid, parsable unit.
      final classSpec = cb.Class((b) => b
        ..name = 'MyClass'
        ..methods.add(methodSpec));

      // The expected string now includes the class wrapper.
      const expected = '''
        class MyClass {
          @override
          bool call() => true;
        }
      ''';

      expectSpec(classSpec, expected);
    });

    test('should build a record type definition', () {
      final typeDefSpec = SyntaxBuilder.typeDef(
        name: '_MyParams',
        definition: SyntaxBuilder.recordType(namedFields: {
          'id': cb.refer('int'),
          'name': cb.refer('String'),
        }),
      );
      expectSpec(typeDefSpec, 'typedef _MyParams = ({int id, String name});');
    });

    group('useCase builder', () {
      // ... (useCase builder tests remain unchanged and are correct)
      test('should build a complete UseCase class with no parameters', () {
        final useCaseSpec = SyntaxBuilder.useCase(
          useCaseName: 'GetCurrentUser',
          repoClassName: 'AuthRepository',
          methodName: 'getCurrentUser',
          returnType: cb.refer('FutureEither<User?>'),
          baseClassName: cb.refer('NullaryUsecase'),
          genericTypes: [cb.refer('User?')],
          callParams: [],
          repoCallPositionalArgs: [],
          repoCallNamedArgs: {},
          annotations: [cb.refer('Injectable').call([])],
        ).first;

        const expected = '''
          @Injectable()
          final class GetCurrentUser implements NullaryUsecase<User?> {
            const GetCurrentUser(this._repository);

            final AuthRepository _repository;

            @override
            FutureEither<User?> call() => _repository.getCurrentUser();
          }
        ''';
        expectSpec(useCaseSpec, expected);
      });

      test('should build a complete UseCase class with a record parameter', () {
        final useCaseSpec = SyntaxBuilder.useCase(
          useCaseName: 'SaveUser',
          repoClassName: 'AuthRepository',
          methodName: 'saveUser',
          returnType: cb.refer('FutureEither<void>'),
          baseClassName: cb.refer('UnaryUsecase'),
          genericTypes: [cb.refer('void'), cb.refer('_SaveUserParams')],
          callParams: [SyntaxBuilder.parameter(name: 'params', type: cb.refer('_SaveUserParams'))],
          repoCallPositionalArgs: [],
          repoCallNamedArgs: {
            'name': cb.refer('params').property('name'),
            'email': cb.refer('params').property('email'),
          },
          annotations: [],
        ).first;

        const expected = '''
          final class SaveUser implements UnaryUsecase<void, _SaveUserParams> {
            const SaveUser(this._repository);

            final AuthRepository _repository;

            @override
            FutureEither<void> call(_SaveUserParams params) =>
                _repository.saveUser(name: params.name, email: params.email);
          }
        ''';
        expectSpec(useCaseSpec, expected);
      });
    });
  });
}
