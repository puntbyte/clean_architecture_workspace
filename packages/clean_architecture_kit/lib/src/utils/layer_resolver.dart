import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:glob/glob.dart';

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
  unknown,
}

class LayerResolver {
  final CleanArchitectureConfig _config;

  LayerResolver(this._config);

  String? _getRelativePath(String absolutePath) {
    final normalized = absolutePath.replaceAll(r'\', '/');
    final libIndex = normalized.indexOf('/lib/');
    if (libIndex == -1) return null;
    return normalized.substring(libIndex + 5); // Path from inside 'lib/'
  }

  ArchLayer getLayer(String path) {
    final relativePath = _getRelativePath(path);
    if (relativePath == null) return ArchLayer.unknown;

    final layerConfig = _config.layers;

    if (layerConfig.projectStructure == 'layer_first') {
      if (relativePath.startsWith('${layerConfig.domainPath}/')) return ArchLayer.domain;
      if (relativePath.startsWith('${layerConfig.dataPath}/')) return ArchLayer.data;
      if (relativePath.startsWith('${layerConfig.presentationPath}/')) {
        return ArchLayer.presentation;
      }
    } else {
      final domainGlob = Glob('${layerConfig.featuresRootPath}/*/domain/**');
      final dataGlob = Glob('${layerConfig.featuresRootPath}/*/data/**');
      final presentationGlob = Glob('${layerConfig.featuresRootPath}/*/presentation/**');

      if (domainGlob.matches(relativePath)) return ArchLayer.domain;
      if (dataGlob.matches(relativePath)) return ArchLayer.data;
      if (presentationGlob.matches(relativePath)) return ArchLayer.presentation;
    }

    return ArchLayer.unknown;
  }

  // Normalization helpers
  String _normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[_\-]'), '');

  String _stripPlural(String s) =>
      (s.endsWith('s') && s.length > 1) ? s.substring(0, s.length - 1) : s;

  bool _segmentMatchesName(String segment, String configuredName) {
    final seg = _normalize(segment);
    final name = _normalize(configuredName);

    if (seg == name) return true;
    if (_stripPlural(seg) == _stripPlural(name)) return true;
    // tolerant fallback to allow close naming variants (small prefixes/suffixes)
    if (seg.startsWith(name) || name.startsWith(seg)) return true;
    return false;
  }

  // Check configuredNames in order and return the first matching configured name found
  // (this respects ordering: earlier configured names are primary).
  bool _firstMatchInOrder(List<String>? configuredNames, List<String> pathSegments) {
    if (configuredNames == null || configuredNames.isEmpty) return false;
    for (final cfgName in configuredNames) {
      for (final seg in pathSegments) {
        if (_segmentMatchesName(seg, cfgName)) return true;
      }
    }

    return false;
  }

  // Helper: read a list from config or fall back to defaults.
  List<String>? _listOrNull(List<String>? fromConfig, List<String> defaults) {
    if (fromConfig == null || fromConfig.isEmpty) return defaults;

    return fromConfig;
  }

  ArchSubLayer getSubLayer(String path) {
    final relativePath = _getRelativePath(path);
    if (relativePath == null) return ArchSubLayer.unknown;

    final pathSegments = relativePath.split('/');
    final layerConfig = _config.layers;
    final layer = getLayer(path);

    // --- Determine candidate names for each sublayer (try config first, else defaults)
    final domainEntityNames = _listOrNull(
      layerConfig.domainEntitiesPaths,
      ['entities'],
    );

    final domainUseCaseNames = _listOrNull(
      layerConfig.domainUseCasesPaths,
      ['usecases', 'interactors', 'use_cases'],
    );

    final domainRepositoryNames = _listOrNull(
      layerConfig.domainRepositoriesPaths,
      ['repositories', 'contracts'],
    );

    final dataModelNames = _listOrNull(
      layerConfig.dataModelsPaths,
      ['models'],
    );

    final dataSourceNames = _listOrNull(
      layerConfig.dataDataSourcesPaths,
      ['datasources', 'sources', 'data_sources'],
    );

    final dataRepositoryNames = _listOrNull(
      layerConfig.dataRepositoriesPaths,
      ['repositories'],
    );

    final presentationManagerNames = _listOrNull(
      layerConfig.presentationManagersPaths,
      ['managers', 'controllers', 'blocs', 'cubit'],
    );

    final presentationWidgetNames = _listOrNull(
      layerConfig.presentationWidgetsPaths,
      ['widgets', 'components'],
    );

    final presentationPagesNames = _listOrNull(
      layerConfig.presentationPagesPaths,
      ['pages', 'screens', 'views'],
    );

    // --- Matching logic, respecting list ordering (primary/default first)
    if (layer == ArchLayer.domain) {
      if (_firstMatchInOrder(domainEntityNames, pathSegments)) return ArchSubLayer.entity;
      if (_firstMatchInOrder(domainUseCaseNames, pathSegments)) return ArchSubLayer.useCase;
      if (_firstMatchInOrder(domainRepositoryNames, pathSegments)) {
        return ArchSubLayer.domainRepository;
      }
    } else if (layer == ArchLayer.data) {
      // <<-- REORDERED: check repositories before data sources to avoid
      // accidental source matches on 'repositories' paths.
      if (_firstMatchInOrder(dataModelNames, pathSegments)) return ArchSubLayer.model;
      if (_firstMatchInOrder(dataRepositoryNames, pathSegments)) return ArchSubLayer.dataRepository;
      if (_firstMatchInOrder(dataSourceNames, pathSegments)) return ArchSubLayer.dataSource;
    } else if (layer == ArchLayer.presentation) {
      if (_firstMatchInOrder(presentationManagerNames, pathSegments)) return ArchSubLayer.manager;
      if (_firstMatchInOrder(presentationWidgetNames, pathSegments)) return ArchSubLayer.widget;
      if (_firstMatchInOrder(presentationPagesNames, pathSegments)) return ArchSubLayer.pages;
    }

    return ArchSubLayer.unknown;
  }
}
