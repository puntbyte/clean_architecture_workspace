// lib/src/models/layer_config.dart
import 'package:clean_architecture_kit/src/utils/map_parsing_extension.dart';

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
    // Now use the extension methods for cleaner parsing
    final layerFirst = map.getMap('layer_first_paths');
    final featureFirst = map.getMap('feature_first_paths');
    final layerDefinitions = map.getMap('layer_definitions');

    final domainDefinitions = layerDefinitions.getMap('domain');
    final dataDefinitions = layerDefinitions.getMap('data');
    final presentationDefinitions = layerDefinitions.getMap('presentation');

    return LayerConfig(
      projectStructure: map.getString('project_structure', orElse: 'feature_first'),
      featuresRootPath: _sanitize(featureFirst.getString('features_root', orElse: 'features')),

      domainPath: _sanitize(layerFirst.getString('domain', orElse: 'domain')),
      domainEntitiesPaths: domainDefinitions.getList('entities'),
      domainUseCasesPaths: domainDefinitions.getList('usecases'),
      domainRepositoriesPaths: domainDefinitions.getList('repositories'),

      dataPath: _sanitize(layerFirst.getString('data', orElse: 'data')),
      dataModelsPaths: dataDefinitions.getList('models'),
      dataDataSourcesPaths: dataDefinitions.getList('data_sources'),
      dataRepositoriesPaths: dataDefinitions.getList('repositories'),

      presentationPath: _sanitize(layerFirst.getString('presentation', orElse: 'presentation')),
      presentationManagersPaths: presentationDefinitions.getList('managers'),
      presentationWidgetsPaths: presentationDefinitions.getList('widgets'),
      presentationPagesPaths: presentationDefinitions.getList('pages'),
    );
  }

  static String _sanitize(String path) {
    var sanitizedPath = path.trim();
    if (path.startsWith('lib/')) sanitizedPath = path.substring(4);
    if (path.startsWith('/')) sanitizedPath = path.substring(1);
    return sanitizedPath;
  }
}
