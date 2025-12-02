// lib/src/configuration/config_keys.dart

/// Central repository for all string keys used in architecture.yaml
abstract class ConfigKeys {
  static const root = _RootKeys();
  static const component = _ComponentKeys();
  static const placeholder = _PlaceholderKeys();
}

class _RootKeys {
  const _RootKeys();

  String get architecture => 'architecture';
  String get include => 'include';
  String get components => 'components';
  String get modules => 'modules';
  String get dependencies => 'dependencies';
  String get typeSafeties => 'type_safeties';
  String get exceptions => 'exceptions';
  String get members => 'members';
  String get usages => 'usages';
  String get annotations => 'annotations';
  String get relationships => 'relationships';
}

abstract class _CommonKeys {
  static const name = 'name';
  static const path = 'path';

  const _CommonKeys._();
}

class _ComponentKeys {
  const _ComponentKeys();

  String get name => _CommonKeys.name;
  String get path => _CommonKeys.path;
  String get default$ => 'default';
  String get pattern => 'pattern';
  String get antipattern => 'antipattern';
  String get grammar => 'grammar';
}


class _PlaceholderKeys {
  const _PlaceholderKeys();

  String get name => '{{name}}';
  String get affix => '{{affix}}';
}
