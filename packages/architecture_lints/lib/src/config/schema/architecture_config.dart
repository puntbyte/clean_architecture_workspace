// lib/src/config/schema/architecture_config.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/schema/annotation_config.dart';
import 'package:architecture_lints/src/config/schema/component_config.dart';
import 'package:architecture_lints/src/config/schema/dependency_config.dart';
import 'package:architecture_lints/src/config/schema/exception_config.dart';
import 'package:architecture_lints/src/config/schema/inheritance_config.dart';
import 'package:architecture_lints/src/config/schema/member_config.dart';
import 'package:architecture_lints/src/config/schema/module_config.dart';
import 'package:architecture_lints/src/config/schema/relationship_config.dart';
import 'package:architecture_lints/src/config/schema/symbol_definition.dart';
import 'package:architecture_lints/src/config/schema/type_definition.dart';
import 'package:architecture_lints/src/config/schema/type_safety_config.dart';
import 'package:architecture_lints/src/config/schema/usage_config.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';

class ArchitectureConfig {
  final List<ComponentConfig> components;
  final List<DependencyConfig> dependencies;
  final List<InheritanceConfig> inheritances;
  final Map<String, TypeDefinition> typeDefinitions;
  final List<TypeSafetyConfig> typeSafeties;
  final List<ExceptionConfig> exceptions;
  final List<MemberConfig> members; // New
  final Map<String, SymbolDefinition> services; // New
  final List<UsageConfig> usages; // New
  final List<AnnotationConfig> annotations; // New
  final List<RelationshipConfig> relationships; // New
  final List<ModuleConfig> modules; // New
  final Map<String, String> templates;
  final List<String> excludes; // New


  const ArchitectureConfig({
    required this.components,
    this.dependencies = const [],
    this.inheritances = const [],
    this.typeDefinitions = const {},
    this.typeSafeties = const [],
    this.exceptions = const [],
    this.members = const [],
    this.services = const {},
    this.usages = const [],
    this.annotations = const [],
    this.relationships = const [],
    this.modules = const [],
    this.templates = const {},
    this.excludes = const [],
  });

  factory ArchitectureConfig.empty() => const ArchitectureConfig(components: []);

  /// Constructs an [ArchitectureConfig] from a parsed YAML map.
  /// Uses helpers to extract and validate `components` and `dependencies`.
  factory ArchitectureConfig.fromYaml(Map<dynamic, dynamic> yaml) {
    final components = _mapMap<ComponentConfig>(
      yaml,
      ConfigKeys.root.components,
      ComponentConfig.fromMapEntry,
    );

    final dependencies = _mapList<DependencyConfig>(
      yaml,
      ConfigKeys.root.dependencies,
      DependencyConfig.fromMap,
    );

    final inheritances = _mapList<InheritanceConfig>(
      yaml,
      ConfigKeys.root.inheritances,
      InheritanceConfig.fromMap,
    );

    // 4. Parse Type Definitions
    final typeDefinitions = <String, TypeDefinition>{};

    // Safely get the 'types' map
    final typesMap = yaml.getMapMap(ConfigKeys.root.types);

    for (final groupEntry in typesMap.entries) {
      final groupKey = groupEntry.key;
      final groupItems = groupEntry.value; // This is a Map<String, dynamic>

      String? currentCascadingImport;

      for (final defEntry in groupItems.entries) {
        final defKey = defEntry.key;
        final fullKey = '$groupKey.$defKey'; // e.g. 'usecase.unary'

        try {
          final def = TypeDefinition.fromDynamic(
            defEntry.value,
            currentImport: currentCascadingImport,
          );

          typeDefinitions[fullKey] = def;

          // Cascade the import to the next item in this group
          if (def.import != null) {
            currentCascadingImport = def.import;
          }
        } catch (e) {
          // print('Failed to parse definition $fullKey: $e');
        }
      }
    }

    final typeSafeties = _mapList<TypeSafetyConfig>(
      yaml,
      ConfigKeys.root.typeSafeties,
      TypeSafetyConfig.fromMap,
    );

    final exceptions = _mapList<ExceptionConfig>(
      yaml,
      ConfigKeys.root.exceptions,
      ExceptionConfig.fromMap,
    );

    final members = _mapList<MemberConfig>(
      yaml,
      ConfigKeys.root.members,
      MemberConfig.fromMap,
    );

    final services = <String, SymbolDefinition>{};
    yaml.getMapMap(ConfigKeys.root.services).forEach((key, value) {
      services[key] = SymbolDefinition.fromMap(value);
    });

    // 6. Parse Usages (List)
    final usages = _mapList<UsageConfig>(
      yaml,
      ConfigKeys.root.usages,
      UsageConfig.fromMap,
    );

    final annotations = _mapList<AnnotationConfig>(
      yaml,
      ConfigKeys.root.annotations,
      AnnotationConfig.fromMap,
    );

    final relationships = _mapList<RelationshipConfig>(
      yaml,
      ConfigKeys.root.relationships,
      RelationshipConfig.fromMap,
    );

    final modules = <ModuleConfig>[];
    final rawModules = yaml['modules'];
    if (rawModules is Map) {
      rawModules.forEach((key, value) {
        modules.add(ModuleConfig.fromMap(key.toString(), value));
      });
    }

    final templates = <String, String>{};
    final rawTemplates = yaml[ConfigKeys.root.templates];

    if (rawTemplates is Map) {
      rawTemplates.forEach((key, value) {
        if (value is String) {
          templates[key.toString()] = value;
        }
      });
    }

    final excludes = yaml.getStringList(ConfigKeys.root.excludes);

    return ArchitectureConfig(
      components: components,
      dependencies: dependencies,
      inheritances: inheritances,
      typeDefinitions: typeDefinitions,
      typeSafeties: typeSafeties,
      exceptions: exceptions,
      members: members,
      services: services, // Add
      usages: usages,     // Add
      annotations: annotations, // Add
      relationships: relationships, // Add
      modules: modules,
      excludes: excludes, // Add
    );
  }

  // ---------- Private helpers to reduce redundancy ----------

  /// Extract a map-of-maps from [yaml] at [key], validate it, and convert each `MapEntry` using
  /// [converter].
  static List<T> _mapMap<T>(
    Map<dynamic, dynamic> yaml,
    String key,
    T Function(MapEntry<String, Map<String, dynamic>>) converter,
  ) {
    final raw = yaml[key];

    if (raw != null && raw is! Map) {
      throw FormatException(
        "Invalid configuration: '$key' must be a Map, but found ${raw.runtimeType}.",
      );
    }

    // getMapMap throws/validates and returns an empty map when absent
    final map = yaml.getMapMap(key);
    return map.entries.map(converter).toList();
  }

  /// Extract a list-of-maps from [yaml] at [key], validate it, and convert each map using
  /// [converter].
  static List<T> _mapList<T>(
    Map<dynamic, dynamic> yaml,
    String key,
    T Function(Map<String, dynamic>) converter,
  ) {
    final raw = yaml[key];

    if (raw != null && raw is! List) {
      throw FormatException(
        "Invalid configuration: '$key' must be a List, but found ${raw.runtimeType}.",
      );
    }

    // getMapList throws/validates and returns an empty list when absent
    final list = yaml.getMapList(key);
    return list.map(converter).toList();
  }
}
