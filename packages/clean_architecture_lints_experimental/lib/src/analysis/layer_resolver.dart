// lib/src/analysis/layer_resolver.dart

import 'package:analyzer/dart/element/element.dart';
import 'package:architecture_lints/src/analysis/arch_component.dart';
import 'package:architecture_lints/src/models/configs/architecture_config.dart';
import 'package:architecture_lints/src/models/configs/module_config.dart';
import 'package:architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:path/path.dart' as p;

class LayerResolver {
  final ArchitectureConfig _config;
  final Map<String, ArchComponent> _componentDirectoryMap;

  LayerResolver(this._config) : _componentDirectoryMap = _createComponentDirectoryMap(_config);

  ArchComponent getComponent(String path, {String? className}) {
    final componentFromPath = _getComponentFromPath(path);

    if (className != null) {
      if (componentFromPath == ArchComponent.manager) {
        return _refineComponent(
          className: className,
          baseComponent: ArchComponent.manager,
          potentialComponents: [
            ArchComponent.eventInterface,
            ArchComponent.stateInterface,
            ArchComponent.manager,
            ArchComponent.stateImplementation,
            ArchComponent.eventImplementation,
          ],
        );
      }

      if (componentFromPath == ArchComponent.source) {
        return _refineComponent(
          className: className,
          baseComponent: ArchComponent.source,
          potentialComponents: [
            ArchComponent.sourceInterface,
            ArchComponent.sourceImplementation,
          ],
        );
      }
    }

    return componentFromPath;
  }

  ArchComponent _getComponentFromPath(String path) {
    final segments = _getRelativePathSegments(path);
    if (segments == null || !_isPathInArchitecturalLayer(segments)) return ArchComponent.unknown;

    for (final segment in segments.reversed) {
      final component = _componentDirectoryMap[segment];
      if (component != null) return component;
    }

    return ArchComponent.unknown;
  }

  ArchComponent _refineComponent({
    required String className,
    required ArchComponent baseComponent,
    required List<ArchComponent> potentialComponents,
  }) {
    for (final component in potentialComponents) {
      final rule = _config.namingConventions.ruleFor(component);
      if (rule != null && NamingUtils.validateName(name: className, template: rule.pattern)) {
        return component;
      }
    }
    return baseComponent;
  }

  bool _isPathInArchitecturalLayer(List<String> segments) {
    final modules = _config.modules;
    if (modules.type == ModuleType.layerFirst) {
      return segments.isNotEmpty &&
          [modules.domain, modules.data, modules.presentation].contains(segments.first);
    } else {
      return segments.length > 2 && segments.first == modules.features;
    }
  }

  List<String>? _getRelativePathSegments(String absolutePath) {
    final normalized = p.normalize(absolutePath);
    final segments = p.split(normalized);
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;

    return segments.sublist(libIndex + 1);
  }

  /// NEW: Identifies the component type based on its supertypes (Inheritance).
  /// This breaks ambiguities when the name doesn't match the location.
  ArchComponent? getComponentFromSupertype(InterfaceElement element) {
    for (final supertype in element.allSupertypes) {
      final library = supertype.element.library;
      // [Analyzer 8.0.0] Use firstFragment.source
      final source = library.firstFragment.source;

      // Check if the supertype definition file belongs to a known architectural component
      final comp = getComponent(source.fullName);

      // We are looking for core architectural identities (Entity, Port, etc.)
      // If we find one, we assume this class IS that component.
      if (comp != ArchComponent.unknown) return comp;
    }
    return null;
  }

  static Map<String, ArchComponent> _createComponentDirectoryMap(ArchitectureConfig config) {
    final map = <String, ArchComponent>{};
    final layers = config.layers;

    void register(List<String> dirs, ArchComponent component) {
      for (final dir in dirs) {
        map[dir] = component;
      }
    }

    register(layers.domain.entity, ArchComponent.entity);
    register(layers.domain.port, ArchComponent.port);
    register(layers.domain.usecase, ArchComponent.usecase);

    register(layers.data.model, ArchComponent.model);
    register(layers.data.source, ArchComponent.source);
    register(layers.data.repository, ArchComponent.repository);

    register(layers.presentation.manager, ArchComponent.manager);
    register(layers.presentation.widget, ArchComponent.widget);
    register(layers.presentation.page, ArchComponent.page);

    return map;
  }
}
