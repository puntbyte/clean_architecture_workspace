// test/helpers/test_data.dart

import 'package:clean_architecture_lints/src/models/configs/architecture_config.dart';

ArchitectureConfig makeConfig({
  String type = 'feature_first',
  String coreDir = 'core',
  String featuresDir = 'features',
  String domainLayerName = 'domain',
  String dataLayerName = 'data',
  String presentationLayerName = 'presentation',
  // Directory names (can be string or list)
  dynamic entityDir = 'entities',
  dynamic portDir = 'ports',
  dynamic usecaseDir = 'usecases',
  dynamic modelDir = 'models',
  dynamic repositoryDir = 'repositories',
  dynamic sourceDir = 'sources',
  dynamic pageDir = 'pages',
  dynamic widgetDir = 'widgets',
  dynamic managerDir = const ['managers', 'bloc', 'cubit'],
  // Rule lists
  List<Map<String, dynamic>>? namingRules,
  List<Map<String, dynamic>>? inheritances,
  List<Map<String, dynamic>>? annotations,
  List<Map<String, dynamic>>? typeSafeties,
  List<Map<String, dynamic>>? dependencies,
  Map<String, dynamic>? services,
  // New Config Sections
  Map<String, dynamic>? typeDefinitions,
  List<Map<String, dynamic>>? errorHandlers,
}) {
  // Default naming rules are often required for LayerResolver to correctly
  // identify components (like separating Source Interface from Implementation).
  final defaultNamingRules = [
    // Domain
    {'on': 'entity', 'pattern': '{{name}}'},
    {'on': 'port', 'pattern': '{{name}}Repository'}, // or {{name}}Port based on your new config
    {'on': 'usecase', 'pattern': '{{name}}'},
    {'on': 'usecase.parameter', 'pattern': '_{{name}}Param'},
    // Data
    {'on': 'model', 'pattern': '{{name}}Model'},
    {'on': 'repository', 'pattern': '{{kind}}{{name}}Repository'},
    {'on': 'source.interface', 'pattern': '{{name}}DataSource'},
    {'on': 'source.implementation', 'pattern': 'Default{{name}}DataSource'},
    // Presentation
    {'on': 'page', 'pattern': '{{name}}Page'},
    {'on': 'widget', 'pattern': '{{name}}Widget'},
    {'on': 'manager', 'pattern': '{{name}}(Bloc|Cubit|Manager)'},
  ];

  return ArchitectureConfig.fromMap({
    'module_definitions': {
      'type': type,
      'core': coreDir,
      'features': featuresDir,
      'layers': {
        'domain': domainLayerName,
        'data': dataLayerName,
        'presentation': presentationLayerName,
      }
    },
    'layer_definitions': {
      'domain': {
        'entity': entityDir,
        'port': portDir,
        'usecase': usecaseDir,
      },
      'data': {
        'model': modelDir,
        'repository': repositoryDir,
        'source': sourceDir,
      },
      'presentation': {
        'page': pageDir,
        'widget': widgetDir,
        'manager': managerDir,
      },
    },
    'naming_conventions': namingRules ?? defaultNamingRules,
    'inheritances': inheritances ?? [],
    'annotations': annotations ?? [],
    'type_safeties': typeSafeties ?? [],
    'dependencies': dependencies ?? [],
    'services': services ?? {
      'service_locator': {'name': ['getIt', 'locator', 'sl']}
    },
    'type_definitions': typeDefinitions ?? {},
    'error_handlers': errorHandlers ?? [],
  });
}
