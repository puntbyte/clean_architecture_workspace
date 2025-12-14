import 'package:architecture_lints/src/actions/context/wrappers/list_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/string_wrapper.dart';
import 'package:architecture_lints/src/actions/context/wrappers/type_wrapper.dart';
import 'package:expressions/expressions.dart';

class GenericWrapper {
  final StringWrapper base;
  final ListWrapper<TypeWrapper> args;

  const GenericWrapper(
    this.base,
    this.args,
  );

  static MemberAccessor<GenericWrapper> get accessor =>
      const MemberAccessor<GenericWrapper>.fallback(_getMember);

  static dynamic _getMember(GenericWrapper obj, String name) => switch (name) {
    'base' => obj.base,
    'args' => obj.args,
    'first' => obj.first,
    'last' => obj.last,
    'length' => obj.length,
    _ => throw ArgumentError('Unknown GenericWrapper property: $name'),
  };

  // --- Convenience Properties for Expressions ---

  /// Returns the first argument (e.g. T in Future< T >).
  TypeWrapper? get first => args.isNotEmpty ? args.first : null;

  /// Returns the last argument (e.g. R in Either< L, R >).
  TypeWrapper? get last => args.isNotEmpty ? args.last : null;

  /// Number of generic arguments.
  int get length => args.length;

  /// Converts to Map for Mustache.
  Map<String, dynamic> toMap() => {
    'base': base,
    'args': args, // ListWrapper will be handled by accessors
    'length': length,
  };
}
