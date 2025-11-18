// test/src/utils/ast_utils_test.dart

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:clean_architecture_lints/src/utils/ast_utils.dart';
import 'package:test/test.dart';

void main() {
  group('AstUtils', () {
    group('getParameterTypeNode', () {
      FormalParameter getFirstParameter(String source) {
        final parseResult = parseString(content: source, throwIfDiagnostics: false);
        final classNode = parseResult.unit.declarations.first as ClassDeclaration;
        final constructor = classNode.members.whereType<ConstructorDeclaration>().first;
        return constructor.parameters.parameters.first;
      }

      test('should return the type when parameter is a simple required positional', () {
        final parameter = getFirstParameter('class C { C(String name); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode?.toSource(), 'String');
      });

      test('should return the type when parameter is a simple required named', () {
        final parameter = getFirstParameter('class C { C({required String name}); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode?.toSource(), 'String');
      });

      test('should return the type when parameter is an optional positional', () {
        final parameter = getFirstParameter('class C { C([String? name]); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode?.toSource(), 'String?');
      });

      test('should return null when parameter is a field formal without an explicit type', () {
        final parameter = getFirstParameter('class C { final String name; C(this.name); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(
          typeNode,
          isNull,
          reason: '`this.name` has no explicit type on the parameter itself.',
        );
      });

      test('should return the type when parameter is a field formal with an explicit type', () {
        final parameter = getFirstParameter('class C { final String name; C(String this.name); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode?.toSource(), 'String');
      });

      test('should return the return type when parameter is a function-typed formal', () {
        final parameter = getFirstParameter('class C { C(void callback()); }');
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(typeNode, isNotNull);
        expect(typeNode?.toSource(), 'void');
      });

      test('should return null when parameter is a super formal without an explicit type', () {
        const source = '''
          class P { P({required String name}); }
          class C extends P { C({required super.name}); }
        ''';
        final parseResult = parseString(content: source, throwIfDiagnostics: false);
        final classC = parseResult.unit.declarations.last as ClassDeclaration;
        final constructor = classC.members.first as ConstructorDeclaration;
        final parameter = constructor.parameters.parameters.first;
        final typeNode = AstUtils.getParameterTypeNode(parameter);
        expect(
          typeNode,
          isNull,
          reason: '`super.name` has no explicit type on the parameter itself.',
        );
      });
    });
  });
}
