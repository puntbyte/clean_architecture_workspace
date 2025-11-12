// lib/src/utils/extensions/iterable_extension.dart

/// An extension on `Iterable` to provide a safe `firstWhereOrNull` method.
extension IterableExtension<T> on Iterable<T> {
  /// Returns the first element that satisfies the given predicate [test].
  ///
  /// If no element satisfies [test], returns `null`.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
