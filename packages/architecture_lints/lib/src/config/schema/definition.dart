// lib/src/config/schema/definition.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/parsing/hierarchy_parser.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class Definition {
  final List<String> types;
  final List<String> identifiers;
  final List<String> imports;
  final String? ref;
  final String? component;
  final List<Definition> arguments;
  final bool isWildcard;

  const Definition({
    this.types = const [],
    this.identifiers = const [],
    this.imports = const [],
    this.ref,
    this.component,
    this.arguments = const [],
    this.isWildcard = false,
  });

  /// Backward compatibility getter.
  String? get type => types.isNotEmpty ? types.first : null;

  String? get import => imports.isNotEmpty ? imports.first : null;

  factory Definition.fromDynamic(dynamic value) {
    if (value == null) return const Definition();

    // 1. Shorthand String -> Single Type in List
    if (value is String) {
      if (value == '*') return const Definition(isWildcard: true);
      return Definition(types: [value]);
    }

    // 2. Map
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      final compRef = map.tryGetString(ConfigKeys.definition.component);
      if (compRef != null) return Definition(component: compRef);

      final refKey = map.tryGetString(ConfigKeys.definition.definition);
      if (refKey != null) return Definition(ref: refKey);

      // Parse Types: Handles both "type: 'String'" and "type: ['A', 'B']"
      final typesList = map.getStringList(ConfigKeys.definition.type);
      if (typesList.contains('*')) return const Definition(isWildcard: true);

      // Parse Imports
      final importsList = map.getStringList(ConfigKeys.definition.import);

      // Parse Identifiers
      // Note: ConfigKeys.definition.identifier should map to 'identifier'
      final ids = map.getStringList(ConfigKeys.definition.identifier);

      // Parse Arguments
      final rawArgs = map[ConfigKeys.definition.argument];
      final args = <Definition>[];
      if (rawArgs != null) {
        if (rawArgs is List) {
          args.addAll(rawArgs.map(Definition.fromDynamic));
        } else {
          args.add(Definition.fromDynamic(rawArgs));
        }
      }

      return Definition(
        types: typesList,
        identifiers: ids,
        imports: importsList,
        arguments: args,
      );
    }

    return const Definition();
  }

  static Map<String, Definition> parseRegistry(Map<String, dynamic> map) {
    return HierarchyParser.parse<Definition>(
      yaml: map,
      factory: (id, node) => Definition.fromDynamic(node),
      cascadeProperties: [ConfigKeys.definition.import],
      shorthandKey: ConfigKeys.definition.type,
      shouldParseNode: (node) {
        if (node is String) return true;
        if (node is Map) {
          return node.containsKey(ConfigKeys.definition.type) ||
              node.containsKey(ConfigKeys.definition.identifier) ||
              node.containsKey(ConfigKeys.definition.definition) ||
              node.containsKey(ConfigKeys.definition.component) ||
              node.containsKey(ConfigKeys.definition.argument);
        }
        return false;
      },
    );
  }

  /// Generates a human-readable description of this definition.
  ///
  /// [registry]: Optional map to resolve `ref` pointers recursively.
  String describe([Map<String, Definition>? registry]) {
    // 1. Wildcard
    if (isWildcard) return 'Any';

    // 2. Component Reference
    if (component != null) return 'Component($component)';

    // 3. Definition Reference (Recursive Lookup)
    if (ref != null) {
      if (registry != null) {
        final resolved = registry[ref];
        if (resolved != null) return resolved.describe(registry);
      }
      // Fallback if registry missing or key not found
      return 'Ref($ref)';
    }

    // 4. Identifiers (e.g. for Services)
    if (identifiers.isNotEmpty) return identifiers.join('|');

    // 5. Types (e.g. for Classes)
    if (types.isNotEmpty) {
      final baseName = types.join('|');

      // Handle Generics (e.g. Future<Either<L, R>>)
      if (arguments.isNotEmpty) {
        final argsDescription = arguments.map((arg) => arg.describe(registry)).join(', ');
        return '$baseName<$argsDescription>';
      }

      return baseName;
    }

    return 'Unknown Definition';
  }

  @override
  String toString() => describe();
}
