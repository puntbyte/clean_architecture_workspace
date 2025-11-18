// lib/src/utils/config_keys.dart

/// A centralized class holding all the string keys used for parsing the
/// `clean_architecture` block in `analysis_options.yaml`.
///
/// This provides a single source of truth, enables compile-time safety,
/// and uses a nested, namespaced structure for clarity and discoverability.
class ConfigKey {
  const ConfigKey._();

  static const root = _RootKeys();
  static const module = _ModuleKeys();
  static const layer = _LayerKeys();
  static const rule = _RuleKeys();
  static const service = _ServiceKeys();
}

/// Keys for the top-level blocks within the `clean_architecture` configuration.
class _RootKeys {
  const _RootKeys();

  String get modules => 'module_definitions';
  String get layers => 'layer_definitions';
  String get namings => 'naming_conventions';
  String get typeSafeties => 'type_safeties';
  String get inheritances => 'inheritances';
  String get annotations => 'annotations';
  String get services => 'services';
}

/// Keys used within the `module_definitions` block.
class _ModuleKeys {
  const _ModuleKeys();

  String get type => 'type';
  String get layers => 'layers';

  String get core => 'core';
  String get coreDir => core;
  String get features => 'features';
  String get featuresDir => features;

  String get domain => 'domain';
  String get domainDir => domain;
  String get data => 'data';
  String get dataDir => data;
  String get presentation => 'presentation';
  String get presentationDir => presentation;
}

/// Keys used within the `layer_definitions` block.
class _LayerKeys {
  const _LayerKeys();

  // Domain Layer
  String get entity => 'entity';
  String get entityDir => 'entities';
  String get usecase => 'usecase';
  String get usecaseDir => 'usecases';
  String get contract => 'contract';
  String get contractDir => 'contracts';

  // Data Layer
  String get model => 'model';
  String get modelDir => 'models';
  String get source => 'source';
  String get sourceDir => 'sources';
  String get repository => 'repository';
  String get repositoryDir => 'repositories';

  // Presentation Layer
  String get manager => 'manager';
  String get managerDir => 'managers';
  String get page => 'page';
  String get pageDir => 'pages';
  String get widget => 'widget';
  String get widgetDir => 'widgets';
}

/// Keys used across various rule definition blocks (`annotations`, `inheritances`, etc.).
class _RuleKeys {
  const _RuleKeys();

  // Annotations, Inheritances, & Type Safeties Keys
  String get on => 'on';
  String get import => 'import';

  // Annotations, Inheritances, & Services Keys
  String get name => 'name';

  // Annotations & Inheritances keys
  String get required => 'required';
  String get allowed => 'allowed';
  String get forbidden => 'forbidden';

  // Annotation & Type Safeties Key
  String get target => 'target';

  // Namings Keys
  String get pattern => 'pattern';
  String get antipattern => 'antipattern';
  String get grammar => 'grammar';

  // Type Safeties Keys
  String get identifier => 'identifier';
  String get unsafeType => 'unsafe_type';
  String get safeType => 'safe_type';

  // Annotations Keys
  String get message => 'message';
}

/// Keys used within the `services` block.
class _ServiceKeys {
  const _ServiceKeys();

  String get dependencyInjection => 'dependency_injection';
  String get serviceLocator => 'service_locator';
}
