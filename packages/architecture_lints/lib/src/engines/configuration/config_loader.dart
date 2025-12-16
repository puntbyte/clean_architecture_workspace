import 'dart:io';

import 'package:architecture_lints/src/engines/configuration/yaml_merger.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/constants/config_keys.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

class ConfigLoader {
  static final Map<String, _CachedEntry> _cache = {};

  static Future<ArchitectureConfig?> loadFromContext(String sourceFile) async {
    // 1. Find Root
    final root = findRootPath(sourceFile);
    if (root == null) return null;

    final configFilePath = p.join(root, ConfigKeys.configFilename);
    final configFile = File(configFilePath);

    if (!configFile.existsSync()) return null;

    final lastModified = configFile.lastModifiedSync();

    if (_cache.containsKey(configFilePath)) {
      final entry = _cache[configFilePath]!;
      if (entry.lastModified.isAtSameMomentAs(lastModified)) return entry.config;
    }

    // 2. Parse
    try {
      final mergedMap = await YamlMerger.loadMergedYaml(configFilePath, projectRoot: root);

      // Pass filePath for debugging context
      final config = ArchitectureConfig.fromYaml(mergedMap, filePath: configFilePath);

      _cache[configFilePath] = _CachedEntry(config, lastModified);
      return config;
    } catch (e, stack) {
      // FIX: Throw error so ArchitectureLintRule can capture it
      throw StateError('Failed to load architecture.yaml at $configFilePath:\n$e\n$stack');
    }
  }

  static String? findRootPath(String filePath) {
    final normalizedPath = p.normalize(p.absolute(filePath));
    var directory = Directory(p.dirname(normalizedPath));

    for (var i = 0; i < 20; i++) {
      final configPath = p.join(directory.path, ConfigKeys.configFilename);
      if (File(configPath).existsSync()) return directory.path;
      if (directory.parent.path == directory.path) break;
      directory = directory.parent;
    }
    return null;
  }

  @visibleForTesting
  static void resetCache() => _cache.clear();
}

class _CachedEntry {
  final ArchitectureConfig config;
  final DateTime lastModified;
  _CachedEntry(this.config, this.lastModified);
}