// lib/src/engines/expression/wrappers/field_wrapper.dart

import 'package:analyzer/dart/ast/ast.dart';
import 'package:architecture_lints/src/engines/expression/expression.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:expressions/expressions.dart';

/// Wraps a class field (VariableDeclaration) to expose name/type for templates.
/// Extends NodeWrapper so it integrates with existing Node-based logic.
class FieldWrapper extends NodeWrapper {
  final VariableDeclaration declaration;

  const FieldWrapper(
    this.declaration, {
    super.definitions = const {},
  }) : super(declaration);

  static MemberAccessor<FieldWrapper> get accessor =>
      const MemberAccessor<FieldWrapper>.fallback(_getMember);

  static dynamic _getMember(FieldWrapper obj, String name) => switch (name) {
    'name' => obj.name,
    'type' => obj.type,
    // Delegate unknown properties to NodeWrapper so parent/file access still works
    _ => NodeWrapper.getMember(obj, name),
  };

  @override
  StringWrapper get name {
    final id = declaration.name.lexeme;
    return StringWrapper(id);
  }

  TypeWrapper get type {
    final elementType = declaration.declaredElement?.type;
    final raw = declaration.initializer?.toSource() ?? '';
    return TypeWrapper(elementType, rawString: raw, definitions: definitions);
  }

  @override
  Map<String, dynamic> toMap() => {
    'name': name,
    'type': type,
  };

  @override
  String toString() => name.value;
}
