extension MapExtensions on Map<dynamic, dynamic> {
  /// Safely retrieves a non-nullable String.
  /// Returns [fallback] if key is missing or value is not a String.
  String getString(String key, {String fallback = ''}) {
    final value = this[key];
    if (value is String) return value;
    return fallback;
  }

  /// Safely retrieves a nullable String.
  /// Returns null (or specific [fallback]) if key is missing or type matches.
  String? tryGetString(String key, {String? fallback}) {
    final value = this[key];
    if (value is String) return value;
    return fallback;
  }

  /// Safely retrieves a boolean.
  /// Useful for flags like 'default: true'.
  bool getBool(String key, {bool fallback = false}) {
    final value = this[key];
    if (value is bool) return value;
    return fallback;
  }

  /// Safely retrieves a List of Strings.
  /// Handles cases where YAML might define a single string but you want a list.
  /// e.g. path: "core" -> ["core"]
  List<String> getStringList(String key) {
    final value = this[key];

    // Filter out non-string elements to be safe

    if (value is List) return value.whereType<String>().toList();

    if (value is String) return [value];

    return [];
  }

  /// Safely retrieves a Map and casts it to <String, dynamic>.
  /// Returns an empty map if key is missing or wrong type.
  Map<String, dynamic> getMap(String key) {
    final value = this[key];

    // Check against the base Map type, because YamlMap is Map<dynamic, dynamic>
    if (value is Map) {
      try {
        // create a new typed Map from the dynamic one
        return Map<String, dynamic>.from(value);
      } catch (e) {
        // If keys aren't strings, return empty
        return {};
      }
    }
    return {};
  }
}
