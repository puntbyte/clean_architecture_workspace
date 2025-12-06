// lib/src/config/schema/architecture_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/annotation_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/definition.dart';
import 'package:architecture_lints/src/config/schema/dependency_config.dart';
import 'package:architecture_lints/src/config/schema/exception_config.dart';
import 'package:architecture_lints/src/config/schema/inheritance_config.dart';
import 'package:architecture_lints/src/config/schema/member_config.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/config/schema/relationship_config.dart';
import 'package:architecture_lints/src/config/schema/type_safety_config.dart';
import 'package:architecture_lints/src/config/schema/usage_config.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';

class ArchitectureConfig {
  final List<ComponentConfig> components;
  final List<ModuleConfig> modules;
  final List<DependencyConfig> dependencies;
  final List<InheritanceConfig> inheritances;
  final List<TypeSafetyConfig> typeSafeties;
  final List<ExceptionConfig> exceptions;
  final List<MemberConfig> members;
  final List<UsageConfig> usages;
  final List<AnnotationConfig> annotations;
  final List<RelationshipConfig> relationships;
  final Map<String, String> templates;
  final List<String> excludes;
  final Map<String, Definition> definitions; // Replaces 'services' and 'typeDefinitions'

  const ArchitectureConfig({
    required this.components,
    this.modules = const [],
    this.dependencies = const [],
    this.inheritances = const [],
    this.typeSafeties = const [],
    this.exceptions = const [],
    this.members = const [],
    this.usages = const [],
    this.annotations = const [],
    this.relationships = const [],
    this.templates = const {},
    this.excludes = const [],
    this.definitions = const {},
  });

  factory ArchitectureConfig.empty() => const ArchitectureConfig(components: []);

  factory ArchitectureConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    // 1. Modules
    final modules = ModuleConfig.parseMap(
      yaml.mustGetMap(ConfigKeys.root.modules),
    );

    // 2. Components (Generic Parser)
    final components = ComponentConfig.parseMap(
      yaml.mustGetMap(ConfigKeys.root.components),
      modules,
    );

    return ArchitectureConfig(
      modules: modules,
      components: components,
      definitions: Definition.parseRegistry(yaml.mustGetMap(ConfigKeys.root.definitions)),

      dependencies: DependencyConfig.parseList(yaml.mustGetMapList(ConfigKeys.root.dependencies)),

      inheritances: InheritanceConfig.parseList(yaml.mustGetMapList(ConfigKeys.root.inheritances)),

      typeSafeties: TypeSafetyConfig.parseList(yaml.mustGetMapList(ConfigKeys.root.typeSafeties)),

      exceptions: ExceptionConfig.parseList(yaml.mustGetMapList(ConfigKeys.root.exceptions)),

      members: MemberConfig.parseList(yaml.mustGetMapList(ConfigKeys.root.members)),

      usages: UsageConfig.parseList(yaml.mustGetMapList(ConfigKeys.root.usages)),

      annotations: AnnotationConfig.parseList(yaml.mustGetMapList(ConfigKeys.root.annotations)),

      relationships: RelationshipConfig.parseList(
        yaml.mustGetMapList(ConfigKeys.root.relationships),
      ),

      // Templates are simple String maps, no schema needed
      templates: yaml.mustGetMap(ConfigKeys.root.templates).map((key, value) {
        if (value is! String) {
          throw FormatException("Template '$key' must be a String.");
        }
        return MapEntry(key, value);
      }),

      excludes: yaml.mustGetStringList(ConfigKeys.root.excludes),


    );
  }
}
