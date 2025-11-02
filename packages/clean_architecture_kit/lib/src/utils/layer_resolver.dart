import 'dart:io';

import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:path/path.dart' as p;

enum ArchLayer { domain, data, presentation, unknown }

enum ArchSubLayer {
  // domain
  entity,
  useCase,
  domainRepository,

  // data
  model,
  dataSource,
  dataRepository,

  // presentation
  manager,
  widget,
  pages,

  // undefined
  unknown,
}

class LayerResolver {
  final CleanArchitectureConfig _config;

  LayerResolver(this._config);

  // A cache to avoid repeatedly searching the filesystem for the project root.
  static final Map<String, String?> _projectRootCache = {};

  /// A robust method to find the project root directory by searching upwards
  /// from a given file's path for a `pubspec.yaml` file.
  String? _findProjectRoot(String absolutePath) {
    var dir = Directory(p.dirname(absolutePath));
    // Check cache first to avoid redundant I/O.
    if (_projectRootCache.containsKey(dir.path)) {
      return _projectRootCache[dir.path];
    }

    while (true) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        _projectRootCache[absolutePath] = dir.path;
        return dir.path;
      }
      // Stop if we reach the filesystem root.
      if (p.equals(dir.parent.path, dir.path)) {
        _projectRootCache[absolutePath] = null;
        return null;
      }
      dir = dir.parent;
    }
  }

  /// Calculates the relative path of a file from inside the `lib/` directory.
  /// Returns `null` if the project root or `lib` directory cannot be found.
  String? _getRelativePath(String absolutePath) {
    final projectRoot = _findProjectRoot(absolutePath);
    if (projectRoot == null) return null;

    final libDir = Directory(p.join(projectRoot, 'lib'));
    if (!libDir.existsSync()) return null;

    // Use the path package to reliably calculate the relative path.
    return p.relative(absolutePath, from: libDir.path);
  }

  List<String>? _getRelativePathSegments(String absolutePath) {
    final normalized = p.normalize(absolutePath);
    final segments = p.split(normalized);
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;
    return segments.sublist(libIndex + 1);
  }

  ArchLayer getLayer(String path) {
    final segments = _getRelativePathSegments(path);
    if (segments == null) return ArchLayer.unknown;
    final layerConfig = _config.layers;
    if (layerConfig.projectStructure == 'layer_first') {
      if (segments.isNotEmpty) {
        if (segments.first == layerConfig.domainPath) return ArchLayer.domain;
        if (segments.first == layerConfig.dataPath) return ArchLayer.data;
        if (segments.first == layerConfig.presentationPath) return ArchLayer.presentation;
      }
    } else { // feature_first
      if (segments.length > 2 && segments[0] == layerConfig.featuresRootPath) {
        final layerName = segments[2];
        if (layerName == 'domain') return ArchLayer.domain;
        if (layerName == 'data') return ArchLayer.data;
        if (layerName == 'presentation') return ArchLayer.presentation;
      }
    }
    return ArchLayer.unknown;
  }

  ArchSubLayer getSubLayer(String path) {
    final layer = getLayer(path);
    if (layer == ArchLayer.unknown) return ArchSubLayer.unknown;
    final pathSegments = _getRelativePathSegments(path);
    if (pathSegments == null) return ArchSubLayer.unknown;
    final layerConfig = _config.layers;

    if (layer == ArchLayer.domain) {
      if (_firstMatchInOrder(layerConfig.domainEntitiesPaths, pathSegments)) return ArchSubLayer.entity;
      if (_firstMatchInOrder(layerConfig.domainUseCasesPaths, pathSegments)) return ArchSubLayer.useCase;
      if (_firstMatchInOrder(layerConfig.domainRepositoriesPaths, pathSegments)) return ArchSubLayer.domainRepository;
    } else if (layer == ArchLayer.data) {
      if (_firstMatchInOrder(layerConfig.dataModelsPaths, pathSegments)) return ArchSubLayer.model;
      if (_firstMatchInOrder(layerConfig.dataRepositoriesPaths, pathSegments)) return ArchSubLayer.dataRepository;
      if (_firstMatchInOrder(layerConfig.dataDataSourcesPaths, pathSegments)) return ArchSubLayer.dataSource;
    } else if (layer == ArchLayer.presentation) {
      if (_firstMatchInOrder(layerConfig.presentationManagersPaths, pathSegments)) return ArchSubLayer.manager;
      if (_firstMatchInOrder(layerConfig.presentationWidgetsPaths, pathSegments)) return ArchSubLayer.widget;
      if (_firstMatchInOrder(layerConfig.presentationPagesPaths, pathSegments)) return ArchSubLayer.pages;
    }
    return ArchSubLayer.unknown;
  }

  // --- Fuzzy Matching Helpers ---

  String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[_\-]'), '');

  String _stripPlural(String s) =>
      (s.endsWith('s') && s.length > 1) ? s.substring(0, s.length - 1) : s;

  bool _segmentMatchesName(String segment, String configuredName) {
    final seg = _normalize(segment);
    final name = _normalize(configuredName);

    if (seg == name) return true;
    if (_stripPlural(seg) == _stripPlural(name)) return true;
    if (seg.startsWith(name) || name.startsWith(seg)) return true;
    return false;
  }

  bool _firstMatchInOrder(List<String> configuredNames, List<String> pathSegments) {
    if (configuredNames.isEmpty) return false;
    for (final cfgName in configuredNames) {
      for (final seg in pathSegments) {
        if (_segmentMatchesName(seg, cfgName)) return true;
      }
    }
    return false;
  }
}
