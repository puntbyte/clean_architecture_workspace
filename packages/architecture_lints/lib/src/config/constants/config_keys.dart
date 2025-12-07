// lib/src/constants/config_keys.dart

abstract class ConfigKeys {
  const ConfigKeys._();

  static const String configFilename = 'architecture.yaml';

  static const root = _RootKeys();
  static const typeDef = _TypeDefinitionKeys();
  static const module = _ModuleKeys(); // New
  static const component = _ComponentKeys();
  static const definition = _DefinitionKeys();
  static const dependency = _DependencyKeys();
  static const inheritance = _InheritanceKeys();
  static const typeSafety = _TypeSafetyKeys();
  static const exception = _ExceptionKeys();
  static const member = _MemberKeys();
  static const service = _ServiceKeys(); // New
  static const usage = _UsageKeys(); // New
  static const annotation = _AnnotationKeys(); // New
  static const relationship = _RelationshipKeys(); // New
  static const vocabulary = _VocabularyKeys();

  static const placeholder = _PlaceholderKeys();
}

class _RootKeys {
  const _RootKeys();

  String get modules => 'modules';
  String get components => 'components';
  String get definitions => 'definitions';
  String get types => 'types';
  String get dependencies => 'dependencies';
  String get inheritances => 'inheritances';
  String get typeSafeties => 'type_safeties';
  String get exceptions => 'exceptions';
  String get members => 'members'; // New
  String get services => 'services'; // New
  String get usages => 'usages'; // New
  String get annotations => 'annotations'; // New
  String get relationships => 'relationships'; // New
  String get templates => 'templates';
  String get vocabulary => 'vocabulary';

  String get excludes => 'excludes';
}


/// There are common keys used redundantly in multiple places.
abstract class _CommonKeys {
  static const name = 'name';
  static const path = 'path';
  static const on = 'on';
  static const required = 'required';
  static const allowed = 'allowed';
  static const forbidden = 'forbidden';

  const _CommonKeys._();
}

class _ModuleKeys {
  const _ModuleKeys();
  String get path => 'path';
  String get default$ => 'default';
  String get strict => 'strict';
}

class _ComponentKeys {
  const _ComponentKeys();

  String get name => _CommonKeys.name;
  String get path => _CommonKeys.path;
  String get default$ => 'default';
  String get pattern => 'pattern';
  String get antipattern => 'antipattern';
  String get grammar => 'grammar'; // New

}

class _TypeDefinitionKeys {
  const _TypeDefinitionKeys();
  String get type => 'type';
  String get import => 'import';
  String get name => 'name'; // Alias for type in some contexts
  String get argument => 'argument'; // New: Recursive definition
  String get definition => 'definition'; // Reference to another key
}

class _DefinitionKeys {
  const _DefinitionKeys();
  String get type => 'type';
  String get import => 'import';
  String get definition => 'definition'; // References
  String get argument => 'argument'; // Generics
  String get component => 'component';

  // New: Merged from Services
  String get identifier => 'identifier';
}

class _DependencyKeys {
  const _DependencyKeys();

  String get on => _CommonKeys.on;

  String get allowed => _CommonKeys.allowed;
  String get forbidden => _CommonKeys.forbidden;

  // Inside the detail object
  String get component => 'component';
  String get import => 'import';
}

class _InheritanceKeys {
  const _InheritanceKeys();

  String get on => _CommonKeys.on;

  String get required => _CommonKeys.required;
  String get allowed => _CommonKeys.allowed;
  String get forbidden => _CommonKeys.forbidden;

  // Fields inside the TypeReference
  String get type => 'type';
  String get import => 'import';
  String get definition => 'definition';
  String get component => 'component';
}

class _ExceptionKeys {
  const _ExceptionKeys();

  String get on => 'on';
  String get role => 'role';
  String get required => 'required';
  String get forbidden => 'forbidden';
  String get conversions => 'conversions';

  // Constraint keys
  String get operation => 'operation';
  String get definition => 'definition';
  String get type => 'type';

  // Conversion keys
  String get fromDefinition => 'from_definition';
  String get toDefinition => 'to_definition';
}

class _TypeSafetyKeys {
  const _TypeSafetyKeys();

  String get on => 'on';
  String get allowed => 'allowed';
  String get forbidden => 'forbidden';

  String get kind => 'kind';
  String get identifier => 'identifier';
  String get definition => 'definition';
  String get type => 'type';
  String get component => 'component';
}

class _MemberKeys {
  const _MemberKeys();

  String get on => 'on';
  String get required => 'required';
  String get allowed => 'allowed';
  String get forbidden => 'forbidden';

  // Constraint fields
  String get kind => 'kind';
  String get identifier => 'identifier';
  String get visibility => 'visibility';
  String get modifier => 'modifier';
}

class _ServiceKeys {
  const _ServiceKeys();
  String get type => 'type';
  String get identifier => 'identifier';
  String get import => 'import';
}

class _UsageKeys {
  const _UsageKeys();
  String get on => 'on';
  String get forbidden => 'forbidden';

  // Constraint keys
  String get kind => 'kind'; // 'access' | 'instantiation'
  String get definition => 'definition'; // Ref to service
  String get component => 'component'; // Ref to component
}

class _AnnotationKeys {
  const _AnnotationKeys();

  String get on => 'on';
  String get mode => 'mode'; // 'strict' | 'implicit'
  String get required => 'required';
  String get allowed => 'allowed';
  String get forbidden => 'forbidden';

  // Constraint keys
  String get type => 'type';
  String get import => 'import';
}

class _RelationshipKeys {
  const _RelationshipKeys();

  String get on => 'on';
  String get element => 'kind'; // 'class' | 'method'
  String get visibility => 'visibility';
  String get required => 'required'; // Map

  // Inside required map
  String get component => 'component';
  String get action => 'action';
}

class _VocabularyKeys {
  const _VocabularyKeys();
  String get nouns => 'nouns';
  String get verbs => 'verbs';
  String get adjectives => 'adjectives';
// We can add adverbs later if needed
}

class _PlaceholderKeys {
  const _PlaceholderKeys();

  String get name => '{{name}}';
  String get affix => '{{affix}}';
}
