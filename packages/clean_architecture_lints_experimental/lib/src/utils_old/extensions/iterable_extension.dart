// lib/src/utils/extensions/iterable_extension.dart

/// An extension on `Iterable` to provide a safe `firstWhereOrNull` method.
extension IterableExtension<T> on Iterable<T> {
  /// Returns the first element that satisfies the given predicate [test].
  ///
  /// If no element satisfies [test], returns `null`.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }

    return null;
  }
}

/// An extension on a nullable `Iterable` to provide null-safe helpers.
extension NullableIterableExtension<T> on Iterable<T?> {
  /// Returns a new lazy [Iterable] with all `null` elements removed.
  /// The resulting iterable is correctly typed as `Iterable<T>`.
  Iterable<T> whereNotNull() sync* {
    for (final element in this) {
      if (element != null) yield element;
    }
  }
}
