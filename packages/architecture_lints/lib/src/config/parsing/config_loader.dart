import 'dart:io';
import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';



class ConfigLoader {
  // Map<PathToYaml, CachedEntry>
  static final Map<String, _CachedEntry> _cache = {};

  static Future<ArchitectureConfig?> loadFromContext(String sourceFile) async {
    final normalizedPath = sourceFile.replaceAll(r'\', '/');

    // 1. Find the project root
    final root = _findProjectRoot(normalizedPath);
    if (root == null) return null;

    final configFilePath = p.join(root, ConfigKeys.configFilename);
    final configFile = File(configFilePath);

    if (!configFile.existsSync()) return null;

    // 2. Get current modification time from disk
    final lastModified = configFile.lastModifiedSync();

    // 3. Check Cache:
    // If we have it cached AND the file hasn't changed since then, return cache.
    if (_cache.containsKey(configFilePath)) {
      final entry = _cache[configFilePath]!;
      if (entry.lastModified.isAtSameMomentAs(lastModified)) {
        return entry.config;
      }
      // If timestamps differ, we proceed to reload (Cache Invalidation)
      // print('ArchLint: Config change detected. Reloading...');
    }

    // 4. Parse from Disk
    try {
      final content = await configFile.readAsString();
      final yamlMap = loadYaml(content);

      if (yamlMap is Map) {
        final config = ArchitectureConfig.fromYaml(yamlMap);

        // Update Cache with new Timestamp
        _cache[configFilePath] = _CachedEntry(config, lastModified);
        return config;
      }
    } catch (e) {
      // print('ArchLint: Config Parse Error $e');
    }

    return null;
  }

  static String? _findProjectRoot(String path) {
    var directory = Directory(p.dirname(path));

    for (int i = 0; i < 20; i++) {
      final configPath = p.join(directory.path, ConfigKeys.configFilename);
      if (File(configPath).existsSync()) {
        return directory.path;
      }

      if (directory.parent.path == directory.path) break;
      directory = directory.parent;
    }
    return null;
  }

  @visibleForTesting
  static void resetCache() {
    _cache.clear();
  }
}

/// Helper class to store Config + Timestamp
class _CachedEntry {
  final ArchitectureConfig config;
  final DateTime lastModified;

  _CachedEntry(this.config, this.lastModified);
}