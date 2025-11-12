// lib/src/models/layer_config.dart

import 'package:clean_architecture_kit/src/utils/extensions/json_map_extension.dart';

class LayerConfig {
  final String projectStructure;
  final String featuresRootPath;

  final String domainPath;
  final List<String> domainEntitiesPaths;
  final List<String> domainUseCasesPaths;
  final List<String> domainRepositoriesPaths;

  final String dataPath;
  final List<String> dataModelsPaths;
  final List<String> dataDataSourcesPaths;
  final List<String> dataRepositoriesPaths;

  final String presentationPath;
  final List<String> presentationManagersPaths;
  final List<String> presentationWidgetsPaths;
  final List<String> presentationPagesPaths;

  const LayerConfig({
    required this.projectStructure,
    required this.featuresRootPath,

    required this.domainPath,
    required this.domainEntitiesPaths,
    required this.domainUseCasesPaths,
    required this.domainRepositoriesPaths,

    required this.dataPath,
    required this.dataModelsPaths,
    required this.dataDataSourcesPaths,
    required this.dataRepositoriesPaths,

    required this.presentationPath,
    required this.presentationManagersPaths,
    required this.presentationWidgetsPaths,
    required this.presentationPagesPaths,
  });

  factory LayerConfig.fromMap(Map<String, dynamic> map) {
    final layerFirst = map.getMap('layer_first_paths');
    final featureFirst = map.getMap('feature_first_paths');
    final layerDefinitions = map.getMap('layer_definitions');

    final domainDefinitions = layerDefinitions.getMap('domain');
    final dataDefinitions = layerDefinitions.getMap('data');
    final presentationDefinitions = layerDefinitions.getMap('presentation');

    return LayerConfig(
      projectStructure: map.getString('project_structure', 'feature_first'),
      featuresRootPath: _sanitize(featureFirst.getString('features_root', 'features')),

      // === Domain Layer Paths ===
      domainPath: _sanitize(layerFirst.getString('domain', 'domain')),
      domainEntitiesPaths: domainDefinitions.getList('entities', ['entities']),
      domainUseCasesPaths: domainDefinitions.getList('use_cases', ['usecases']),
      domainRepositoriesPaths: domainDefinitions.getList('repositories', ['contracts']),

      // === Data Layer Paths ===
      dataPath: _sanitize(layerFirst.getString('data', 'data')),
      dataModelsPaths: dataDefinitions.getList('models', ['models']),
      dataDataSourcesPaths: dataDefinitions.getList('data_sources', ['sources']),
      dataRepositoriesPaths: dataDefinitions.getList('repositories', ['repositories']),

      // === Presentation Layer Paths ===
      presentationPath: _sanitize(layerFirst.getString('presentation', 'presentation')),
      presentationManagersPaths: presentationDefinitions
          .getList('managers', ['managers', 'bloc', 'cubit', 'provider']),
      presentationWidgetsPaths: presentationDefinitions.getList('widgets', ['widgets']),
      presentationPagesPaths: presentationDefinitions.getList('pages', ['pages']),
    );
  }

  static String _sanitize(String path) {
    var sanitized = path;
    if (sanitized.startsWith('lib/')) sanitized = sanitized.substring(4);
    if (sanitized.startsWith('/')) sanitized = sanitized.substring(1);
    return sanitized;
  }
}
