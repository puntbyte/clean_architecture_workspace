import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/config/parsing/hierarchy_parser.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class Definition {
  /// The class name (e.g. 'Future', 'GetIt', 'int').
  final String? type;

  /// Variable, Property, or Method names (e.g. ['sl', 'getIt', 'setup']).
  /// Used primarily for Usage checks.
  final List<String> identifiers;

  /// Strict package import URI (e.g. 'package:get_it/get_it.dart').
  final String? import;

  /// Reference to another key in the definitions registry (e.g. 'failure.base').
  final String? ref;

  /// Reference to an architectural component (e.g. 'model').
  /// Used to enforce that a type belongs to a specific layer.
  final String? component;

  /// Recursive generic arguments (e.g. <Failure, T>).
  final List<Definition> arguments;

  /// If true, this definition matches anything (used for '*').
  final bool isWildcard;

  const Definition({
    this.type,
    this.identifiers = const [],
    this.import,
    this.ref,
    this.component,
    this.arguments = const [],
    this.isWildcard = false,
  });

  /// Factory to parse a definition value which can be a String or a Map.
  /// [currentImport] allows inheriting the import from a parent context (if applicable).
  factory Definition.fromDynamic(dynamic value, {String? currentImport}) {
    if (value == null) return const Definition();

    // 1. Shorthand String: 'MyClass' or '*'
    if (value is String) {
      if (value == '*') return const Definition(isWildcard: true);
      return Definition(type: value, import: currentImport);
    }

    // 2. Detailed Map
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      // --- References ---

      // A. Component Reference
      final compRef = map.tryGetString(ConfigKeys.definition.component);
      if (compRef != null) {
        return Definition(component: compRef);
      }

      // B. Definition Reference
      final refKey = map.tryGetString(ConfigKeys.definition.definition);
      if (refKey != null) {
        return Definition(ref: refKey);
      }

      // --- Explicit Definition ---

      final typeName = map.tryGetString(ConfigKeys.definition.type);
      if (typeName == '*') return const Definition(isWildcard: true);

      final explicitImport = map.tryGetString(ConfigKeys.definition.import);
      final resolvedImport = explicitImport ?? currentImport;

      // Parse Identifiers (String or List)
      final rawIds = map[ConfigKeys.definition.identifiers];
      final ids = <String>[];
      if (rawIds is String) ids.add(rawIds);
      if (rawIds is List) ids.addAll(rawIds.map((e) => e.toString()));

      // Parse Recursive Arguments
      final rawArgs = map[ConfigKeys.definition.argument];
      final args = <Definition>[];

      if (rawArgs != null) {
        if (rawArgs is List) {
          // Argument list: [ {type: A}, {type: B} ]
          args.addAll(
            rawArgs.map((e) => Definition.fromDynamic(e, currentImport: resolvedImport)),
          );
        } else {
          // Single argument shorthand: { type: A }
          args.add(Definition.fromDynamic(rawArgs, currentImport: resolvedImport));
        }
      }

      return Definition(
        type: typeName,
        identifiers: ids,
        import: resolvedImport,
        arguments: args,
      );
    }

    // Fail safe for invalid config types
    return const Definition();
  }

  /// Parses the 'definitions' registry using HierarchyParser.
  static Map<String, Definition> parseRegistry(Map<String, dynamic> map) {
    return HierarchyParser.parse<Definition>(
      yaml: map,
      factory: (id, node) => Definition.fromDynamic(node),
      // Valid if it's a String (shorthand) OR a Map with keys
      shouldParseNode: (node) {
        if (node is String) return true; // Shorthand 'MyClass' is valid
        if (node is Map) {
          return node.containsKey(ConfigKeys.definition.type) ||
              node.containsKey(ConfigKeys.definition.identifiers) ||
              node.containsKey(ConfigKeys.definition.definition) ||
              node.containsKey(ConfigKeys.definition.component) ||
              node.containsKey(ConfigKeys.definition.argument);
        }
        return false;
      },
    );
  }

  bool get isEmpty =>
      type == null &&
          identifiers.isEmpty &&
          ref == null &&
          component == null &&
          !isWildcard;

  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    if (isWildcard) return '*';
    if (ref != null) return 'Ref($ref)';
    if (component != null) return 'Component($component)';

    final base = type ?? (identifiers.isNotEmpty ? identifiers.first : '?');
    if (arguments.isEmpty) return base;

    return '$base<${arguments.join(', ')}>';
  }
}