// lib/src/utils/extensions/json_map_extension.dart

/// An extension on `Map<String, dynamic>` to provide safe, reusable methods
/// for parsing configuration values from a YAML file.
extension JsonMapExtension on Map<String, dynamic> {
  /// Safely retrieves a nested map for a given [key].
  ///
  /// If the value for the key is not a map or is null, this returns an
  /// empty map, preventing runtime errors.
  Map<String, dynamic> getMap(String key) {
    final value = this[key];
    if (value is Map) return Map<String, dynamic>.from(value);

    return {};
  }

  /// Safely retrieves a list of strings for a given [key].
  ///
  /// Expected strict behavior:
  /// - If the value is a `List` and *every* element is a `String`, return it.
  /// - Otherwise return [orElse].
  List<String> getList(String key, [List<String> orElse = const []]) {
    final value = this[key];
    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>().toList();
    }

    return orElse;
  }

  /// Safely retrieves a string for a given [key], falling back to a default.
  ///
  /// If the value for the key is not a string or is null, this returns the
  /// provided [orElse] value.
  String getString(String key, [String orElse = '']) {
    final value = this[key];
    if (value is String) return value;

    return orElse;
  }

  /// Safely retrieves a string for a given [key], returning null if it's
  /// missing or not a string. This is for truly optional properties.
  String? getOptionalString(String key) {
    final value = this[key];
    if (value is String) return value;

    return null;
  }

  /// Safely retrieves a boolean for a given [key], falling back to a default.
  ///
  /// If the value for the key is not a boolean or is null, this returns the
  /// provided [orElse] value, which defaults to `false`.
  bool getBool(String key, [bool orElse = false]) {
    final value = this[key];
    if (value is bool) return value;
    return orElse;
  }
}
