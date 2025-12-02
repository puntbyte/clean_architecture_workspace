// lib/src/configuration/config_loader.dart
import 'dart:io';

import 'package:architecture_lints/src/configuration/component_config.dart';
import 'package:architecture_lints/src/configuration/parsing/config_keys.dart';
import 'package:architecture_lints/src/configuration/project_config.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ConfigLoader {
  static ProjectConfig? _cachedConfig;

  // NEW: Store the last error message for debugging
  static String? loadError;

  static ProjectConfig? getCachedConfig() => _cachedConfig;

  static Future<ProjectConfig?> load(String rootPath) async {
    if (_cachedConfig != null) return _cachedConfig;

    // Reset error on new load attempt
    loadError = null;

    final filePath = p.join(rootPath, 'architecture.yaml');
    final file = File(filePath);

    if (!file.existsSync()) {
      // Try fallback
      final altPath = p.join(rootPath, 'architecture.yml');
      final altFile = File(altPath);
      if (!altFile.existsSync()) {
        // ERROR 1: File not found
        loadError = 'Config file not found. \nChecked paths:\n1. $filePath\n2. $altPath';
        return null;
      }
      return _parseFile(altFile);
    }

    return _parseFile(file);
  }

  static Future<ProjectConfig?> _parseFile(File file) async {
    try {
      final content = await file.readAsString();
      if (content.trim().isEmpty) {
        loadError = 'Config file is empty: ${file.path}';
        return null;
      }

      final yaml = loadYaml(content);

      if (yaml is! YamlMap) {
        loadError = 'YAML format error: Root must be a Map (key-value pairs). File: ${file.path}';
        return null;
      }

      _cachedConfig = parseYaml(yaml);
      return _cachedConfig;
    } catch (e) {
      // ERROR 2: Parsing failed
      loadError = 'YAML Syntax Error in ${file.path}:\n$e';
      return null;
    }
  }

  @visibleForTesting
  static void reset() {
    _cachedConfig = null;
    loadError = null;
  }

  @visibleForTesting
  static ProjectConfig parseYaml(YamlMap yaml) {
    final components = <String, ComponentConfig>{};

    if (yaml.containsKey(ConfigKeys.root.components)) {
      final compMap = yaml[ConfigKeys.root.components] as YamlMap;

      for (final key in compMap.keys) {
        final id = key.toString();
        final node = compMap[key];
        final config = _parseComponent(id, node);
        if (config != null) {
          components[id] = config;
        }
      }
    }

    return ProjectConfig(components: components);
  }

  static ComponentConfig? _parseComponent(String id, dynamic node) {
    if (node is! YamlMap) return null;

    var path = node[ConfigKeys.component.path]?.toString();
    if (path != null) path = p.normalize(path);

    return ComponentConfig(
      id: id,
      name: node[ConfigKeys.component.name]?.toString() ?? id,
      path: path,
      pattern: node[ConfigKeys.component.pattern]?.toString(),
      antipattern: node[ConfigKeys.component.antipattern]?.toString(),
      grammar: node[ConfigKeys.component.grammar]?.toString(),
    );
  }
}