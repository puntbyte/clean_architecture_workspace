// lib/src/utils/map_extensions.dart

extension MapExtensions on Map<dynamic, dynamic> {
  /// Safely retrieves a non-nullable String.
  /// Returns [fallback] if key is missing or value is not a String.
  String getString(String key, {String fallback = ''}) {
    final value = this[key];
    if (value is String) return value;
    return fallback;
  }

  /// Retrieves a String when present; returns [fallback] if key is missing.
  /// Throws [FormatException] if the key exists but is not a String.
  String mustGetString(String key, {String fallback = ''}) {
    final raw = this[key];
    if (raw == null) return fallback;
    if (raw is String) return raw;
    throw FormatException(
      "Invalid configuration: '$key' must be a String, but found ${raw.runtimeType}.",
    );
  }

  /// Safely retrieves a nullable String.
  /// Returns null (or specific [fallback]) if key is missing or type mismatches.
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

  /// Retrieves a bool when present; returns [fallback] if key is missing.
  /// Throws [FormatException] if the key exists but is not a bool.
  bool mustGetBool(String key, {bool fallback = false}) {
    final raw = this[key];
    if (raw == null) return fallback;
    if (raw is bool) return raw;
    throw FormatException(
      "Invalid configuration: '$key' must be a bool, but found ${raw.runtimeType}.",
    );
  }

  /// Safely retrieves a List of Strings.
  /// Handles cases where YAML might define a single string but you want a list.
  /// e.g. path: "core" -> ["core"]
  List<String> getStringList(String key) {
    final value = this[key];

    // Filter out non-string elements to be safe
    if (value is List) return value.map((e) => e.toString()).toList();
    //if (value is List) return value.whereType<String>().toList();

    // Handle single string promoted to list
    if (value is String) return [value];

    return [];
  }

  /// Retrieves a List< String > when present; returns [fallback] if key is missing.
  /// Throws [FormatException] if the key exists but cannot be interpreted as List< String >.
  List<String> mustGetStringList(String key, {List<String>? fallback}) {
    final raw = this[key];
    final fb = fallback ?? <String>[];

    if (raw == null) return fb;

    if (raw is String) return [raw];

    if (raw is List) {
      // ensure all elements are strings
      if (raw
          .whereType<String>()
          .length != raw.length) {
        throw FormatException(
          "Invalid configuration: '$key' must be a List<String>. One or more elements are not "
              'Strings.',
        );
      }
      return raw.cast<String>();
    }

    throw FormatException(
      "Invalid configuration: '$key' must be a List<String> or a String, but found "
          '${raw.runtimeType}.',
    );
  }

  /// Safely retrieves a List of Maps.
  /// Used for parsing lists of objects (e.g., rules configuration).
  ///
  /// Filters out items in the list that are not Maps.
  List<Map<String, dynamic>> getMapList(String key) {
    final value = this[key];

    // Case 1: List of items
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map((item) {
        try {
          return Map<String, dynamic>.from(item);
        } catch (_) {
          return <String, dynamic>{};
        }
      })
          .where((map) => map.isNotEmpty)
          .toList();
    }

    // Case 2: Single Map (Polymorphic)
    if (value is Map) {
      try {
        final map = Map<String, dynamic>.from(value);
        if (map.isNotEmpty) return [map];
      } catch (_) {}
    }

    return [];
  }

  /// Retrieves a List< Map< String,dynamic >> when present; returns [fallback] if key is missing.
  /// Throws [FormatException] if the key exists but is not a List of Maps or maps cannot be cast.
  List<Map<String, dynamic>> mustGetMapList(String key, {List<Map<String, dynamic>>? fallback}) {
    final raw = this[key];
    final fb = fallback ?? <Map<String, dynamic>>[];

    if (raw == null) return fb;

    if (raw is! List) {
      throw FormatException(
        "Invalid configuration: '$key' must be a List, but found ${raw.runtimeType}.",
      );
    }

    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) {
        throw FormatException(
          "Invalid configuration: element #$i in '$key' must be a Map, but found "
              '${item.runtimeType}.',
        );
      }
      try {
        result.add(Map<String, dynamic>.from(item));
      } on FormatException catch (_) {
        throw FormatException(
          "Invalid configuration: element #$i in '$key' has non-String keys and cannot be cast to "
              'Map<String,dynamic>.',
        );
      }
    }
    return result;
  }

  /// Safely retrieves a Map and casts it to < String, dynamic >.
  /// Returns an empty map if key is missing or wrong type.
  Map<String, dynamic> getMap(String key) {
    final value = this[key];

    // Check against the base Map type, because YamlMap is Map<dynamic, dynamic>
    if (value is Map) {
      try {
        // create a new typed Map from the dynamic one
        return Map<String, dynamic>.from(value);
      } on FormatException catch (e) {
        // If keys aren't strings, return empty
        return {};
      }
    }
    return {};
  }

  /// Retrieves a Map< String,dynamic > when present; returns [fallback] if key is missing.
  /// Throws [FormatException] if the key exists but is not a Map or cannot be cast.
  Map<String, dynamic> mustGetMap(String key, {Map<String, dynamic>? fallback}) {
    final raw = this[key];
    final fb = fallback ?? <String, dynamic>{};

    if (raw == null) return fb;

    if (raw is! Map) {
      throw FormatException(
        "Invalid configuration: '$key' must be a Map, but found ${raw.runtimeType}.",
      );
    }

    try {
      return Map<String, dynamic>.from(raw);
    } on FormatException catch (_) {
      throw FormatException(
        "Invalid configuration: '$key' contains non-String keys and cannot be cast to "
            'Map<String,dynamic>.',
      );
    }
  }

  /// Safely retrieves a Map of Maps.
  /// Used for nested configurations like `components: { domain: { ... } }`.
  ///
  /// - Skips entries where the key is not a String.
  /// - Skips entries where the value is not a Map.
  Map<String, Map<String, dynamic>> getMapMap(String key) {
    final value = this[key];

    if (value is Map) {
      final result = <String, Map<String, dynamic>>{};

      value.forEach((k, v) {
        // 1. Key must be String
        if (k is String) {
          // 2. Value must be Map
          if (v is Map) {
            try {
              result[k] = Map<String, dynamic>.from(v);
            } catch (_) {
              // Ignore malformed child maps
            }
          }
        }
      });

      return result;
    }

    return {};
  }

  /// Retrieves a Map< String, Map< String,dynamic >> when present; returns [fallback] if key is
  /// missing.
  /// Throws [FormatException] if the key exists but is not a Map-of-Map or contains invalid
  /// entries.
  Map<String, Map<String, dynamic>> mustGetMapMap(String key, {
    Map<String, Map<String, dynamic>>? fallback,
  }) {
    final raw = this[key];
    final fb = fallback ?? <String, Map<String, dynamic>>{};

    if (raw == null) return fb;

    if (raw is! Map) {
      throw FormatException(
        "Invalid configuration: '$key' must be a Map, but found ${raw.runtimeType}.",
      );
    }

    final result = <String, Map<String, dynamic>>{};
    raw.forEach((k, v) {
      if (k is! String) {
        throw FormatException(
          "Invalid configuration: key '$k' in '$key' must be a String (found ${k.runtimeType}).",
        );
      }
      if (v is! Map) {
        throw FormatException(
          "Invalid configuration: value for key '$k' in '$key' must be a Map, but found "
              '${v.runtimeType}.',
        );
      }
      try {
        result[k] = Map<String, dynamic>.from(v);
      } on FormatException catch (_) {
        throw FormatException(
          "Invalid configuration: nested map for key '$k' in '$key' has non-String keys and cannot "
              'be cast to Map<String,dynamic>.',
        );
      }
    });

    return result;
  }

  /// Generic typed getter that throws on wrong type; returns [fallback] when missing.
  /// Usage: mustGetAs< List< String >>('paths', fallback: [])
  T? mustGetAs<T>(String key, {T? fallback}) {
    final raw = this[key];
    if (raw == null) return fallback;
    if (raw is T) return raw;
    throw FormatException(
      "Invalid configuration: '$key' must be a $T, but found ${raw.runtimeType}.",
    );
  }
}
