import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/node_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/parameter_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:expressions/expressions.dart';

class MethodWrapper extends NodeWrapper {
  final MethodDeclaration method;

  const MethodWrapper(
    this.method, {
    super.definitions = const {},
  }) : super(method);

  static MemberAccessor<MethodWrapper> get accessor =>
      const MemberAccessor<MethodWrapper>.fallback(_getMember);

  static dynamic _getMember(MethodWrapper obj, String name) => switch (name) {
    'returnType' => obj.returnType,
    'returnTypeInner' => obj.returnTypeInner,
    'parameters' => obj.parameters,
    _ => NodeWrapper.getMember(obj, name),
  };

  TypeWrapper get returnType =>
      TypeWrapper(method.returnType?.type, rawString: 'void', definitions: definitions);

  StringWrapper get returnTypeInner => returnType.innerType;

  ListWrapper<ParameterWrapper> get parameters {
    final params = method.parameters?.parameters ?? <FormalParameter>[];
    final wrapped = params.map((p) => ParameterWrapper(p, definitions: definitions)).toList();
    return ListWrapper(wrapped);
  }

  @override
  Map<String, dynamic> toMap() {
    final base = super.toMap()
      ..addAll({
        'returnType': returnType,
        'returnTypeInner': returnTypeInner,
        'parameters': {
          'list': parameters, // ListWrapper is handled by accessors
          'length': parameters.length,
          'isEmpty': parameters.isEmpty,
          'isNotEmpty': parameters.isNotEmpty,
          'hasMany': parameters.hasMany,
          'isSingle': parameters.isSingle,
        },
      });
    return base;
  }
}
