// lib/src/config/schema/type_definition.dart

import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class TypeDefinition {
  /// The class name (e.g. 'Future', 'Either', 'int').
  final String? type;

  /// Strict package import URI.
  final String? import;

  /// Reference to another key in the types registry (e.g. 'failure.base').
  final String? definitionReference;

  /// List of generic type arguments (e.g. < Failure, T >).
  final List<TypeDefinition> arguments;

  /// If true, this definition matches anything (used for '*').
  final bool isWildcard;

  const TypeDefinition({
    this.type,
    this.import,
    this.definitionReference,
    this.arguments = const [],
    this.isWildcard = false,
  });

  /// Recursively parses a single definition value.
  factory TypeDefinition.fromDynamic(dynamic value, {String? currentImport}) {
    // 1. Shorthand String
    if (value is String) {
      if (value == '*') return const TypeDefinition(isWildcard: true);
      return TypeDefinition(type: value, import: currentImport);
    }

    // 2. Map Definition
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);

      final defRef = map.tryGetString(ConfigKeys.typeDef.definition);
      if (defRef != null) {
        return TypeDefinition(definitionReference: defRef);
      }

      final typeName =
          map.tryGetString(ConfigKeys.typeDef.type) ?? map.tryGetString(ConfigKeys.typeDef.name);

      final explicitImport = map.tryGetString(ConfigKeys.typeDef.import);
      final resolvedImport = explicitImport ?? currentImport;

      if (typeName == '*') {
        return const TypeDefinition(isWildcard: true);
      }

      final rawArgs = map[ConfigKeys.typeDef.argument];
      final args = <TypeDefinition>[];

      if (rawArgs != null) {
        if (rawArgs is List) {
          args.addAll(
            rawArgs.map((e) => TypeDefinition.fromDynamic(e, currentImport: resolvedImport)),
          );
        } else {
          args.add(TypeDefinition.fromDynamic(rawArgs, currentImport: resolvedImport));
        }
      }

      return TypeDefinition(
        type: typeName,
        import: resolvedImport,
        arguments: args,
      );
    }

    throw FormatException('Invalid type definition: $value');
  }

  /// Parses the top-level 'types' configuration block.
  /// Handles flattening of groups (e.g. 'usecase.unary') and cascading imports.
  static Map<String, TypeDefinition> parseRegistry(Map<String, Map<String, dynamic>> rawGroups) {
    final registry = <String, TypeDefinition>{};

    for (final groupEntry in rawGroups.entries) {
      final groupKey = groupEntry.key;
      final groupItems = groupEntry.value;

      String? currentCascadingImport;

      for (final defEntry in groupItems.entries) {
        final defKey = defEntry.key;
        final fullKey = '$groupKey.$defKey'; // Flatten: 'group.key'

        try {
          final def = TypeDefinition.fromDynamic(
            defEntry.value,
            currentImport: currentCascadingImport,
          );

          registry[fullKey] = def;

          // Update cascading import context for next item in group
          if (def.import != null) {
            currentCascadingImport = def.import;
          }
        } catch (e) {
          throw FormatException("Error parsing type definition '$fullKey': $e");
        }
      }
    }

    return registry;
  }

  @override
  String toString() {
    if (isWildcard) return '*';
    if (definitionReference != null) return 'Ref($definitionReference)';
    final base = type ?? '?';
    if (arguments.isEmpty) return base;
    return '$base<${arguments.join(', ')}>';
  }
}
