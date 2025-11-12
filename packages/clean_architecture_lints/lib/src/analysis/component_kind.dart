// lib/src/analysis/component_kind.dart

/// A type-safe enum representing the universal `kind` tags for all
/// architectural components defined in the `analysis_options.yaml`.
enum ComponentKind {
  // Layers
  domainLayer,
  dataLayer,
  presentationLayer,

  // Domain Components
  businessObject,         // "entity"
  businessContract,       // "contract"
  repositoryContract,     // "contract.repository"
  sourceContract,         // "contract.source"
  businessLogic,          // "usecase"

  // Data Components
  dataModel,              // "model"
  repositoryImplementation, // "repository"
  sourceImplementation,     // "source"

  // Presentation Components
  stateManager,           // "manager"
  viewEventParent,        // "manager.event"
  viewEventInterface,     // "manager.event.interface"
  viewEventImplementation,// "manager.event.implementation"
  viewStateParent,        // "manager.state"
  viewStateInterface,     // "manager.state.interface"
  viewStateImplementation,// "manager.state.implementation"
  uiLayout,               // "page"
  uiComponent,            // "widget"

  unknown;

  /// A convenience factory to create a `ComponentKind` from a string `kind`
  /// tag parsed from the YAML configuration.
  ///
  /// Defaults to `unknown` if the string does not match any known kind.
  factory ComponentKind.fromKindString(String? kindString) {
    for (final kind in ComponentKind.values) {
      if (kind.name == kindString?.replaceAll('_', '').toLowerCase()) {
        return kind;
      }
    }
    // A more direct mapping would be better if possible. Let's refine.
    return ComponentKind.values.firstWhere(
          (e) => e.name.toLowerCase() == (kindString?.replaceAll('_', '').toLowerCase() ?? ''),
      orElse: () => ComponentKind.unknown,
    );
  }

  // A more robust mapping
  static ComponentKind fromString(String? kindString) {
    return switch (kindString) {
      'domain_layer' => domainLayer,
      'data_layer' => dataLayer,
      'presentation_layer' => presentationLayer,
      'business_object' => businessObject,
      'repository_contract' => repositoryContract,
      'source_contract' => sourceContract,
      'business_logic' => businessLogic,
      'data_model' => dataModel,
      'repository_implementation' => repositoryImplementation,
      'source_implementation' => sourceImplementation,
      'state_manager' => stateManager,
      'view_event_interface' => viewEventInterface,
      'view_event_implementation' => viewEventImplementation,
      'view_state_interface' => viewStateInterface,
      'view_state_implementation' => viewStateImplementation,
      'ui_layout' => uiLayout,
      'ui_component' => uiComponent,
      _ => unknown,
    };
  }
}
