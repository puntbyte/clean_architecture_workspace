
import 'package:architecture_lints/src/engines/expression/expression.dart';
import 'package:architecture_lints/src/schema/config/architecture_config.dart';
import 'package:architecture_lints/src/schema/constraints/annotation_constraint.dart';
import 'package:architecture_lints/src/schema/definitions/type_definition.dart';
import 'package:collection/collection.dart';
import 'package:expressions/expressions.dart';

/// Wraps [ArchitectureConfig] to provide helper methods for the Action Engine.
class ConfigWrapper {
  final ArchitectureConfig _config;

  const ConfigWrapper(this._config);

  static MemberAccessor<ConfigWrapper> get accessor =>
      const MemberAccessor<ConfigWrapper>.fallback(_getMember);

  static dynamic _getMember(ConfigWrapper obj, String name) => switch (name) {
    'namesFor' => obj.namesFor,
    'definitionFor' => obj.definitionFor,
    'annotationsFor' => obj.annotationsFor,
    _ => throw ArgumentError('Unknown ConfigWrapper property: $name'),
  };

  /// Semantic helper: config.definitionFor('usecase.unary')
  /// Returns a Map representation of the definition, allowing usage like:
  /// `config.definitionFor('...').type` (via map key access).
  Map<String, dynamic>? definitionFor(String key) => _config.definitions[key]?.toMap();

  /// Helper to find naming configuration for a specific component ID.
  Map<String, dynamic>? namesFor(String componentId) {
    final component = _config.components.firstWhereOrNull(
      (component) => component.id == componentId,
    );

    if (component == null) return null;

    ListWrapper<StringWrapper> wrap(List<String> list) =>
        ListWrapper(list.map(StringWrapper.new).toList());

    return {
      'pattern': wrap(component.patterns),
      'antipattern': wrap(component.antipatterns),
      'grammar': wrap(component.grammar),
      'path': wrap(component.paths),
    };
  }

  /// Helper to find required annotations for a specific component ID.
  Map<String, dynamic> annotationsFor(String componentId) {
    final rule = _config.annotations.firstWhereOrNull((r) {
      if (r.onIds.contains(componentId)) return true;
      if (r.onIds.any((id) => componentId.endsWith('.$id') || componentId == id)) return true;
      return false;
    });

    if (rule == null) {
      return {
        'required': <TypeDefinition>[],
        'forbidden': <TypeDefinition>[],
        'allowed': <TypeDefinition>[],
      };
    }

    List<TypeDefinition> mapConstraints(List<AnnotationConstraint> constraints) {
      final definitions = <TypeDefinition>[];

      for (final constraint in constraints) {
        for (final type in constraint.types) {
          definitions.add(
            TypeDefinition(
              types: [type],
              imports: constraint.import != null ? [constraint.import!] : [],
            ),
          );
        }
      }

      return definitions;
    }

    // Note: If you want these lists to support .hasMany/.isEmpty in templates,
    // you might want to wrap these lists in ListWrapper here, or ensure
    // Definition.toMap() is sufficient for your template needs.
    // Currently returns List<Definition> which works for iteration.
    return {
      'required': mapConstraints(rule.required),
      'forbidden': mapConstraints(rule.forbidden),
      'allowed': mapConstraints(rule.allowed),
    };
  }
}
