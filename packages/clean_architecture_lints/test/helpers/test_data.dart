// test/helpers/test_data.dart

import 'package:clean_architecture_lints/src/models/architecture_config.dart';

/// A powerful test data factory for creating a complete and valid
/// [ArchitectureConfig] object for use in unit tests.
///
/// It provides sensible defaults for all configuration options and allows any
/// specific property to be overridden by passing it as a named parameter.
/// This ensures that tests can be written concisely and are robust against
/// missing configuration errors.
ArchitectureConfig makeConfig({
  // --- Module Overrides ---
  String type = 'feature_first',
  String coreDir = 'core',
  String featuresDir = 'features',
  String domainLayerName = 'domain',
  String dataLayerName = 'data',
  String presentationLayerName = 'presentation',

  // --- Layer Directory Overrides (accepts String or List<String>) ---
  dynamic entityDir = 'entities',
  dynamic contractDir = 'contracts',
  dynamic usecaseDir = 'usecases',
  dynamic modelDir = 'models',
  dynamic repositoryDir = 'repositories',
  dynamic sourceDir = 'sources',
  dynamic pageDir = 'pages',
  dynamic widgetDir = 'widgets',
  dynamic managerDir = const ['managers', 'bloc', 'cubit'],

  // --- Rule List Overrides ---
  List<Map<String, dynamic>>? namingRules,
  List<Map<String, dynamic>>? inheritances,
  List<Map<String, dynamic>>? locations,
  List<Map<String, dynamic>>? annotations,
  List<Map<String, dynamic>>? typeSafeties,

  // --- Service Overrides ---
  Map<String, dynamic>? services,
}) {
  /// A comprehensive set of default naming rules, one for each ArchComponent.
  /// This prevents lints from failing due to missing rules and makes the
  /// default configuration more realistic and robust.
  final defaultNamingRules = [
    // Domain
    {'on': 'entity', 'pattern': '{{name}}'},
    {'on': 'contract', 'pattern': '{{name}}Repository'},
    {'on': 'usecase', 'pattern': '{{name}}'},
    {'on': 'usecase.parameter', 'pattern': '_{{name}}Param'},
    // Data
    {'on': 'model', 'pattern': '{{name}}Model'},
    {'on': 'repository.implementation', 'pattern': 'Default{{name}}Repository'},
    {'on': 'source.interface', 'pattern': '{{name}}DataSource'},
    {'on': 'source.implementation', 'pattern': 'Default{{name}}DataSource'},
    // Presentation
    {'on': 'page', 'pattern': '{{name}}Page'},
    {'on': 'widget', 'pattern': '{{name}}Widget'},
    {'on': 'manager', 'pattern': '{{name}}(Bloc|Cubit|Manager)'},
    {'on': 'event.interface', 'pattern': '{{name}}Event'},
    {'on': 'state.interface', 'pattern': '{{name}}State'},
    // Generic patterns for implementations are common, which is why refinement is needed.
    {'on': 'event.implementation', 'pattern': '{{name}}'},
    {'on': 'state.implementation', 'pattern': '{{name}}'},
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
      'domain': {'entity': entityDir, 'contract': contractDir, 'usecase': usecaseDir},
      'data': {'model': modelDir, 'repository': repositoryDir, 'source': sourceDir},
      'presentation': {'page': pageDir, 'widget': widgetDir, 'manager': managerDir},
    },

    'naming_conventions': namingRules ?? defaultNamingRules,
    'inheritances': inheritances ?? [],
    'locations': locations ?? [],
    'annotations': annotations ?? [],
    'type_safeties': typeSafeties ?? [],
    'services': services ?? {
      'service_locator': {
        'name': ['getIt', 'locator', 'sl'],
      }
    },
  });
}
