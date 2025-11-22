// test/src/fixes/create_use_case_fix_test.dart

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_lints/src/fixes/create_use_case_fix.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:test/test.dart';

void main() {
  group('CreateUseCaseFix.buildParameterConfigFromParams', () {
    final dummyOutput = cb.refer('int');

    test('nullary (no params) returns nullary base class', () {
      final parsed = parseString(content: 'class A { void doSomething() {} }');
      final method = parsed.unit.declarations
          .whereType<ClassDeclaration>()
          .first
          .members
          .whereType<MethodDeclaration>()
          .first;

      final config = CreateUseCaseFix.buildParameterConfigFromParams(
        params: method.parameters?.parameters ?? [],
        methodName: 'doSomething',
        outputType: dummyOutput,
        unaryName: 'UnaryUsecase',
        nullaryName: 'NullaryUsecase',
      );

      expect(config.baseClassName.symbol, equals('NullaryUsecase'));
      expect(config.genericTypes.length, equals(1));
      expect(config.callParams, isEmpty);
    });

    test('unary (single positional param) returns unary base class and positional arg', () {
      final parsed = parseString(content: 'class A { void getById(int id) {} }');
      final method = parsed.unit.declarations
          .whereType<ClassDeclaration>()
          .first
          .members
          .whereType<MethodDeclaration>()
          .first;

      final config = CreateUseCaseFix.buildParameterConfigFromParams(
        params: method.parameters?.parameters ?? [],
        methodName: 'getById',
        outputType: dummyOutput,
        unaryName: 'UnaryUsecase',
        nullaryName: 'NullaryUsecase',
      );

      expect(config.baseClassName.symbol, equals('UnaryUsecase'));
      expect(config.genericTypes.length, equals(2));
      expect(config.callParams.length, equals(1));
      expect(config.repoCallPositionalArgs.length, equals(1));
      expect(config.repoCallNamedArgs, isEmpty);
      expect(config.callParams.first.name, equals('id'));
    });

    test('multi parameters produce a record type & params wrapper', () {
      final parsed = parseString(content: 'class A { void search(int id, String name) {} }');
      final method = parsed.unit.declarations
          .whereType<ClassDeclaration>()
          .first
          .members
          .whereType<MethodDeclaration>()
          .first;

      final config = CreateUseCaseFix.buildParameterConfigFromParams(
        params: method.parameters?.parameters ?? [],
        methodName: 'search',
        outputType: dummyOutput,
        unaryName: 'UnaryUsecase',
        nullaryName: 'NullaryUsecase',
      );

      expect(config.baseClassName.symbol, equals('UnaryUsecase'));
      expect(config.genericTypes.length, equals(2));
      expect(config.callParams.length, equals(1));
      expect(config.recordTypeDef, isNotNull);
      // call param should be named 'params' and of type = the record name
      expect(config.callParams.first.name, equals('params'));
    });
  });
}
