import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/actions/context/wrappers/node_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:expressions/expressions.dart';

class ParameterWrapper extends NodeWrapper {
  final FormalParameter param;

  const ParameterWrapper(
    this.param, {
    super.definitions = const {},
  }) : super(param);

  static MemberAccessor<ParameterWrapper> get accessor =>
      const MemberAccessor<ParameterWrapper>.fallback(_getMember);

  static dynamic _getMember(ParameterWrapper obj, String name) => switch (name) {
    'type' => obj.type,
    'isNamed' => obj.isNamed,
    'isPositional' => obj.isPositional,
    'isRequired' => obj.isRequired,
    _ => NodeWrapper.getMember(obj, name),
  };

  @override
  StringWrapper get name {
    final token = param.name;
    return StringWrapper(token?.lexeme ?? '');
  }

  TypeWrapper get type {
    final type = param.declaredFragment?.element.type;
    return TypeWrapper(type, rawString: 'dynamic', definitions: definitions);
  }

  bool get isNamed => param.isNamed;

  bool get isPositional => param.isPositional;

  bool get isRequired => param.isRequired;

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
    'isNamed': isNamed,
    'isPositional': isPositional,
    'isRequired': isRequired,
  };
}
