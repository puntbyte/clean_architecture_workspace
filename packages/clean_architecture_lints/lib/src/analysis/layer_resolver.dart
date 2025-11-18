// lib/src/analysis/layer_resolver.dart

import 'package:clean_architecture_lints/src/analysis/arch_component.dart';
import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/models/module_config.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:path/path.dart' as p;

/// A utility class to resolve the architectural component of a given file path.
/// It uses a pre-computed lookup map for high performance.
class LayerResolver {
  final ArchitectureConfig _config;
  final Map<String, ArchComponent> _componentDirectoryMap;

  LayerResolver(this._config) : _componentDirectoryMap = _createComponentDirectoryMap(_config);

  /// Resolves the architectural component for a given file path and optional class name.
  ArchComponent getComponent(String path, {String? className}) {
    final componentFromPath = _getComponentFromPath(path);

    if (className != null) {
      if (componentFromPath == ArchComponent.manager) {
        return _refineManagerComponent(className);
      }
      if (componentFromPath == ArchComponent.source) {
        return _refineSourceComponent(className);
      }
    }

    return componentFromPath;
  }

  /// Determines the component type by checking path segments against the pre-computed map.
  ArchComponent _getComponentFromPath(String path) {
    final segments = _getRelativePathSegments(path);
    if (segments == null || !_isPathInArchitecturalLayer(segments)) {
      return ArchComponent.unknown;
    }

    // Iterate backwards as the component dir is usually at the end of the path
    for (final segment in segments.reversed) {
      final component = _componentDirectoryMap[segment];
      if (component != null) {
        return component;
      }
    }

    return ArchComponent.unknown;
  }

  /// Refines a component by checking its class name against a series of naming rules
  /// in a specific, hardcoded order to prevent ambiguity.
  ArchComponent _refineManagerComponent(String className) {
    // Check for the MOST specific patterns (interfaces with suffixes) first.
    if (_matches(className, ArchComponent.event)) return ArchComponent.event;
    if (_matches(className, ArchComponent.state)) return ArchComponent.state;

    // Then, check for the manager/bloc/cubit pattern.
    if (_matches(className, ArchComponent.manager)) return ArchComponent.manager;

    // Finally, check for the generic implementation patterns. The order between
    // these two only matters if their patterns are also ambiguous.
    if (_matches(className, ArchComponent.stateImplementation))
      return ArchComponent.stateImplementation;
    if (_matches(className, ArchComponent.eventImplementation))
      return ArchComponent.eventImplementation;

    // If no specific name matches, it's a generic manager.
    return ArchComponent.manager;
  }

  ArchComponent _refineSourceComponent(String className) {
    if (_matches(className, ArchComponent.sourceImplementation)) {
      return ArchComponent.sourceImplementation;
    }
    // Default to the interface if the implementation pattern doesn't match.
    return ArchComponent.source;
  }

  /// Helper to check if a class name matches the pattern for a given component.
  bool _matches(String className, ArchComponent component) {
    final rule = _config.namingConventions.getRuleFor(component);
    return rule != null && NamingUtils.validateName(name: className, template: rule.pattern);
  }

  // --- Path Helper Functions ---

  bool _isPathInArchitecturalLayer(List<String> segments) {
    final modules = _config.module;
    if (modules.type == ModuleType.layerFirst) {
      return segments.isNotEmpty &&
          [modules.domain, modules.data, modules.presentation].contains(segments.first);
    } else {
      // feature_first
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

  static Map<String, ArchComponent> _createComponentDirectoryMap(ArchitectureConfig config) {
    final map = <String, ArchComponent>{};
    final layers = config.layer;
    // Domain Layer
    for (final dir in layers.domain.entity) {
      map[dir] = ArchComponent.entity;
    }
    for (final dir in layers.domain.contract) {
      map[dir] = ArchComponent.contract;
    }
    for (final dir in layers.domain.usecase) {
      map[dir] = ArchComponent.usecase;
    }
    // Data Layer
    for (final dir in layers.data.model) {
      map[dir] = ArchComponent.model;
    }
    for (final dir in layers.data.repository) {
      map[dir] = ArchComponent.repository;
    }
    for (final dir in layers.data.source) {
      map[dir] = ArchComponent.source;
    }
    // Presentation Layer
    for (final dir in layers.presentation.page) {
      map[dir] = ArchComponent.page;
    }
    for (final dir in layers.presentation.widget) {
      map[dir] = ArchComponent.widget;
    }
    for (final dir in layers.presentation.manager) {
      map[dir] = ArchComponent.manager;
    }
    return map;
  }
}
