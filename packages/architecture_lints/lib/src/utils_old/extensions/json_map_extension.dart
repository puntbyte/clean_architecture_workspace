// lib/src/utils/extensions/json_map_extension.dart

/// Type alias for JSON maps used throughout the configuration parsing.
typedef JsonMap = Map<String, dynamic>;

/// Type alias for lists of strings, commonly used in configuration values.
typedef StringList = List<String>;

/// Type alias for lists of JSON maps, used for nested rule configurations.
typedef JsonMapList = List<JsonMap>;

/// An extension on [JsonMap] to provide safe, reusable methods for parsing
/// configuration values from YAML files.
extension JsonMapExtension on JsonMap {
  /// Safely retrieves a boolean value for [key], falling back to [orElse]
  /// if the key is missing or the value is not a bool.
  bool asBool(String key, {bool orElse = false}) {
    final value = this[key];
    return value is bool ? value : orElse;
  }

  /// Safely retrieves a string value for [key], falling back to [orElse]
  /// if the key is missing or the value is not a string.
  String asString(String key, {String orElse = ''}) {
    final value = this[key];
    return value is String ? value : orElse;
  }

  /// Safely retrieves a string value for [key], returning null if the key
  /// is missing, the value is null, or the value is not a string.
  /// This is for truly optional configuration properties.
  String? asStringOrNull(String key) {
    final value = this[key];
    return value is String ? value : null;
  }

  /// Safely retrieves a list of strings for [key].
  ///
  /// Handles three cases from YAML:
  /// 1. Valid `List<String>` → returns as-is
  /// 2. Single `String` → wraps in a list
  /// 3. Missing, null, or wrong type → returns [orElse]
  StringList asStringList(String key, {StringList orElse = const []}) {
    final value = this[key];

    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>().toList();
    }

    if (value is String) {
      return [value];
    }

    return orElse;
  }

  /// Safely retrieves a nested [JsonMap] for [key].
  ///
  /// If the value is a generic `Map`, it's converted to [JsonMap].
  /// Returns [orElse] if the key is missing or the value is not a map.
  JsonMap asMap(String key, {JsonMap orElse = const {}}) {
    final value = this[key];

    // Already the correct type
    if (value is JsonMap) return value;

    // Convert from generic map
    if (value is Map) return JsonMap.from(value);

    return orElse;
  }

  /// Safely retrieves a list of maps for [key].
  ///
  /// Filters the list to only include valid maps and converts them to [JsonMap].
  /// Returns [orElse] if the key is missing or the value is not a list.
  JsonMapList asMapList(String key, {JsonMapList orElse = const []}) {
    final value = this[key];

    if (value is List) {
      // Filter and convert only the valid map items
      return value.whereType<Map<dynamic, dynamic>>().map(JsonMap.from).toList();
    }

    return orElse;
  }
}
