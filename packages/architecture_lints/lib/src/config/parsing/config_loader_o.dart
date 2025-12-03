// lib/src/configuration/config_loader.dart

import 'dart:io';

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/architecture_config.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class ConfigLoader {

  // Singleton Cache
  static ArchitectureConfig? _cachedConfig;

  static final Map<String, ArchitectureConfig> _cache = {};

  /// Locates and loads the config by walking up from the [sourceFile].
  static Future<ArchitectureConfig?> loadFromContext(String sourceFile) async {
    final root = _findProjectRoot(sourceFile);
    if (root == null) return null;

    if (_cache.containsKey(root)) {
      return _cache[root];
    }

    final file = File(p.join(root, ConfigKeys.configFilename));
    if (!file.existsSync()) return null;

    try {
      final content = await file.readAsString();
      final yamlMap = loadYaml(content);
      if (yamlMap is Map) {
        final config = ArchitectureConfig.fromYaml(yamlMap);
        _cache[root] = config;
        return config;
      }
    } catch (e) {
      // print('ArchLint: Parse Error $e');
    }
    return null;
  }

  /// Recursively walks up directories to find architecture.yaml
  static String? _findProjectRoot(String path) {
    var directory = Directory(p.dirname(path));
    // Safety break to prevent infinite loops (e.g., checking root of drive)
    int depth = 0;
    while (depth < 20) {
      final configFile = File(p.join(directory.path, ConfigKeys.configFilename));
      if (configFile.existsSync()) {
        return directory.path;
      }

      final parent = directory.parent;
      if (parent.path == directory.path) break; // Reached system root
      directory = parent;
      depth++;
    }
    return null; // Not found
  }




  /*static ProjectConfig? _cachedConfig;

  // NEW: Store the last error message for debugging
  static String? loadError;

  static ProjectConfig? getCachedConfig() => _cachedConfig;

  static Future<ProjectConfig?> loadX(String rootPath) async {
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

      return _cachedConfig = parseYaml(yaml);
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
    final dependencies = <LayerConfig>[]; // <--- Init list

    // 1. Parse Components (Existing)
    if (yaml.containsKey(ConfigKeys.root.components)) {
      final compMap = yaml[ConfigKeys.root.components] as YamlMap;
      for (final key in compMap.keys) {
        final id = key.toString();
        final node = compMap[key];
        final config = _parseComponent(id, node);
        if (config != null) components[id] = config;
      }
    }

    // 2. Parse Dependencies (NEW)
    if (yaml.containsKey(ConfigKeys.root.dependencies)) {
      final depList = yaml[ConfigKeys.root.dependencies];
      if (depList is YamlList) {
        for (final node in depList) {
          final config = _parseLayerConfig(node);
          if (config != null) dependencies.add(config);
        }
      }
    }

    return ProjectConfig(
      components: components,
      dependencies: dependencies, // <--- Pass to constructor
    );
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

  static LayerConfig? _parseLayerConfig(dynamic node) {
    if (node is! YamlMap) return null;

    // Parse 'on': can be String or List<String>
    final onNode = node[ConfigKeys.dependency.on];
    final onLayers = _parseStringOrList(onNode);
    if (onLayers.isEmpty) return null;

    return LayerConfig(
      onLayers: onLayers,
      allowed: _parseDependencyRule(node[ConfigKeys.dependency.allowed]),
      forbidden: _parseDependencyRule(node[ConfigKeys.dependency.forbidden]),
    );
  }

  static DependencyRule? _parseDependencyRule(dynamic node) {
    if (node == null) return null;

    // If shorthand string/list (assumed to be components for now, or mix)
    // But config spec says: allowed: { component: ..., import: ... }
    // Let's support the detailed Map format first.
    if (node is YamlMap) {
      return DependencyRule(
        components: _parseStringOrList(node[ConfigKeys.dependency.component]),
        imports: _parseStringOrList(node[ConfigKeys.dependency.import]),
      );
    }

    // Fallback if user just writes allowed: 'domain' (shorthand for component)
    if (node is String || node is YamlList) {
      return DependencyRule(components: _parseStringOrList(node));
    }

    return null;
  }

  static List<String> _parseStringOrList(dynamic node) {
    if (node == null) return [];
    if (node is String) return [node];
    if (node is YamlList) return node.map((e) => e.toString()).toList();
    return [];
  }*/
}
