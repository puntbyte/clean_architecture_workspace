// lib/src/constants/config_keys.dart

// 1. Declare parts
import 'package:architecture_lints/src/utils/token_syntax.dart';

part 'keys/root_keys.dart';
part 'keys/annotation_keys.dart';
part 'keys/component_keys.dart';
part 'keys/type_keys.dart';
part 'keys/dependency_keys.dart';
part 'keys/inheritance_keys.dart';
part 'keys/type_safety_keys.dart';
part 'keys/exception_keys.dart';
part 'keys/member_keys.dart';
part 'keys/module_keys.dart';
part 'keys/usage_keys.dart';
part 'keys/relationship_keys.dart';
part 'keys/template_keys.dart';
part 'keys/regex_keys.dart';
part 'keys/placeholder_keys.dart';

abstract class ConfigKeys {
  const ConfigKeys._();

  static const String configFilename = 'architecture.yaml';

  static const root = _RootKeys();
  static const typeDef = _TypeDefinitionKeys();
  static const module = _ModuleKeys();
  static const component = _ComponentKeys();
  static const definition = _TypeKeys();
  static const dependency = _DependencyKeys();
  static const inheritance = _InheritanceKeys();
  static const typeSafety = _TypeSafetyKeys();
  static const exception = _ExceptionKeys();
  static const member = _MemberKeys();
  static const service = _ServiceKeys();
  static const usage = _UsageKeys();
  static const annotation = _AnnotationKeys();
  static const relationship = _RelationshipKeys();
  static const vocabulary = _VocabularyKeys();
  static const template = _TemplateKeys();
  static const regex = _RegexKeys();
  static const variable = _VariableKeys();
  static const action = _ActionKeys();

  static const placeholder = _PlaceholderKeys();
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


class _TypeDefinitionKeys {
  const _TypeDefinitionKeys();
  String get type => 'type';
  String get import => 'import';
  String get name => 'name'; // Alias for type in some contexts
  String get argument => 'argument'; // New: Recursive definition
  String get definition => 'definition'; // Reference to another key
}

class _VariableKeys {
  const _VariableKeys();

  String get from => 'from';
  String get value => 'value';
  String get spread => 'spread';
  String get select => 'select';

  String get transformer => 'transformer'; // NEW
}

class _ServiceKeys {
  const _ServiceKeys();
  String get type => 'type';
  String get identifier => 'identifier';
  String get import => 'import';
}


class _VocabularyKeys {
  const _VocabularyKeys();
  String get nouns => 'nouns';
  String get verbs => 'verbs';
  String get adjectives => 'adjectives';
// We can add adverbs later if needed
}

class _ActionKeys {
  const _ActionKeys();

  String get write => 'write';
  String get strategy => 'strategy';
  String get placement => 'placement';
  String get filename => 'filename';
  String get identifier => 'identifier';
}
