// lib/src/utils/json_map_extension.dart
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
  /// If the value for the key is not a list, is null, or contains non-string
  /// elements, this returns an empty list, ensuring type safety.
  List<String> getList(String key) {
    final value = this[key];
    if (value is List) return value.whereType<String>().toList();

    return [];
  }

  /// Safely retrieves a string for a given [key], falling back to a default.
  ///
  /// If the value for the key is not a string or is null, this returns the
  /// provided [orElse] value.
  String getString(String key, {String orElse = ''}) {
    final value = this[key];
    if (value is String) return value;

    return orElse;
  }
}
