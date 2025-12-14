import 'dart:collection';
import 'package:expressions/expressions.dart';

/// Wraps a list to provide template-friendly properties.
class ListWrapper<E> with IterableMixin<E> {
  final List<E> _inner;

  const ListWrapper(this._inner);

  static MemberAccessor<ListWrapper<dynamic>> get accessor =>
      const MemberAccessor<ListWrapper<dynamic>>.fallback(_getMember);

  static dynamic _getMember(ListWrapper<dynamic> obj, String name) => switch (name) {
    'hasMany' => obj.hasMany,
    'isSingle' => obj.isSingle,
    'isEmpty' => obj.isEmpty,
    'isNotEmpty' => obj.isNotEmpty,
    'length' => obj.length,
    'first' => obj.first,
    'last' => obj.last,
    'at' => obj.at,
    _ => throw ArgumentError('Unknown ListWrapper property: $name'),
  };

  @override
  Iterator<E> get iterator => _inner.iterator;

  @override
  int get length => _inner.length;

  E operator [](int index) => _inner[index];

  bool get hasMany => length > 1;

  bool get isSingle => length == 1;

  @override
  bool get isEmpty => _inner.isEmpty;

  @override
  bool get isNotEmpty => _inner.isNotEmpty;

  @override
  E get first => _inner.first;

  @override
  E get last => _inner.last;

  E? at(int index) {
    if (index >= 0 && index < length) return _inner[index];
    return null;
  }

  @override
  List<E> toList({bool growable = true}) => _inner.toList(growable: growable);
}
