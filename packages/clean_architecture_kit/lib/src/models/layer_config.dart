// lib/src/models/layer_config.dart

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
    final layerFirst = _getMap(map, 'layer_first_paths');
    final featureFirst = _getMap(map, 'feature_first_paths');
    final layerDefinitions = _getMap(map, 'layer_definitions');

    final domainDefinitions = _getMap(layerDefinitions, 'domain');
    final dataDefinitions = _getMap(layerDefinitions, 'data');
    final presentationDefinitions = _getMap(layerDefinitions, 'presentation');

    return LayerConfig(
      projectStructure: map['project_structure'] as String? ?? 'feature_first',
      featuresRootPath: _sanitize(featureFirst['features_root'] as String? ?? 'features'),

      domainPath: _sanitize(layerFirst['domain'] as String? ?? 'domain'),
      domainEntitiesPaths: _getList(domainDefinitions, 'entities'),
      domainUseCasesPaths: _getList(domainDefinitions, 'usecases'),
      domainRepositoriesPaths: _getList(domainDefinitions, 'repositories'),

      dataPath: _sanitize(layerFirst['data'] as String? ?? 'data'),
      dataModelsPaths: _getList(dataDefinitions, 'models'),
      dataDataSourcesPaths: _getList(dataDefinitions, 'data_sources'),
      dataRepositoriesPaths: _getList(dataDefinitions, 'repositories'),

      presentationPath: _sanitize(layerFirst['presentation'] as String? ?? 'presentation'),
      presentationManagersPaths: _getList(presentationDefinitions, 'managers'),
      presentationWidgetsPaths: _getList(presentationDefinitions, 'widgets'),
      presentationPagesPaths: _getList(presentationDefinitions, 'pages'),
    );
  }

  static String _sanitize(String path) {
    if (path.startsWith('lib/')) path = path.substring(4);
    if (path.startsWith('/')) path = path.substring(1);
    return path;
  }

  static Map<String, dynamic> _getMap(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static List<String> _getList(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is List) return value.whereType<String>().toList();
    return [];
  }
}
