// lib/src/utils/config/config_keys.dart

/// A centralized class holding all the string keys used for parsing the
/// `clean_architecture` block in `analysis_options.yaml`.
///
/// This provides a single source of truth, enables compile-time safety,
/// and uses a nested, namespaced structure for clarity and discoverability.
class ConfigKey {
  const ConfigKey._();

  /// The root key for the plugin configuration.
  static const String cleanArchitecture = 'clean_architecture';

  static const root = _RootKeys();
  static const module = _ModuleKeys();
  static const layer = _LayerKeys();
  static const rule = _RuleKeys();
  static const service = _ServiceKeys();
  static const dependency = _DependencyKeys();
  static const proxy = _ProxyKeys();
  static const error = _ErrorKeys();
  static const type = _TypeKeys();

  /// General keys used across multiple configuration blocks.
  static const common = _CommonKeys();
}

class _CommonKeys {
  const _CommonKeys();

  String get on => 'on';

  String get name => 'name';

  String get import => 'import';

  String get allowed => 'allowed';

  String get forbidden => 'forbidden';

  String get required => 'required';

  String get message => 'message';
}

/// Keys for the top-level blocks within the `clean_architecture` configuration.
class _RootKeys {
  const _RootKeys();

  String get modules => 'module_definitions';

  String get layers => 'layer_definitions';

  String get namings => 'naming_conventions';

  String get typeSafeties => 'type_safeties';

  String get inheritances => 'inheritances';

  String get dependencies => 'dependencies';

  String get annotations => 'annotations';

  String get services => 'services';

  String get typeDefinitions => 'type_definitions';

  String get errorHandlers => 'error_handlers';
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

  String get port => 'port';

  String get portDir => 'ports';

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

class _TypeKeys {
  const _TypeKeys();

  String get key => 'key';

  String get name => 'name';

  String get import => 'import';
}

class _ErrorKeys {
  const _ErrorKeys();

  String get role => 'role';

  String get operation => 'operation';

  String get targetType => 'target_type';

  String get conversions => 'conversions';

  String get fromType => 'from_type';

  String get toType => 'to_type';
}

/// Keys used across various rule definition blocks (`annotations`, `inheritances`, etc.).
class _RuleKeys {
  const _RuleKeys();

  String get definition => 'definition'; // NEW

  String get kind => 'kind'; // New

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

  String get parameters => 'parameters';

  String get returns => 'returns';

  // Annotations Keys
  String get message => 'message';

  String get component => 'component';

  String get type => 'type';
}

class _ServiceKeys {
  const _ServiceKeys();

  String get serviceLocator => 'service_locator'; // Fixed to match yaml
  String get locatorNames => 'name';
}

class _ProxyKeys {
  const _ProxyKeys();

  String get package => 'package:';

  String get lib => 'lib/';
}

// New keys helper
class _DependencyKeys {
  const _DependencyKeys();

  String get on => 'on';

  String get allowed => 'allowed';

  String get forbidden => 'forbidden';

  String get component => 'component'; // Used for both layers and components
  String get package => 'package';
}
