// lib/src/analysis/arch_component.dart

/// Represents the specific architectural component a file or class corresponds to.
///
/// The `snake_case` names of these enum values are the source of truth for keys
/// in the `analysis_options.yaml` configuration (e.g., `on: 'use_case'`).
enum ArchComponent {
  // --- Domain Components ---
  entity('entity', label: 'Entity'),
  contract('contract', label: 'Repository Interface'),
  usecase('usecase', label: 'Use Case'),
  usecaseParameter('usecase.parameter', label: 'Use Case Parameter'),

  // --- Data Components ---
  model('model', label: 'Model'),
  repository('repository.implementation', label: 'Repository Implementation'),
  source('source.interface', label: 'Data Source Interface'),
  sourceImplementation('source.implementation', label: 'Data Source Implementation'),

  // --- Presentation Components ---
  page('page', label: 'Page'),
  widget('widget', label: 'Widget'),
  manager('manager', label: 'Manager'),
  event('event.interface', label: 'Event'),
  eventImplementation('event.implementation', label: 'Event Implementation'),
  state('state.interface', label: 'State'),
  stateImplementation('state.implementation', label: 'State Implementation'),

  // --- Unknown Component ---
  unknown('unknown', label: 'Unknown');

  /// The `snake_case` identifier used in `analysis_options.yaml`.
  final String id;

  /// A user-friendly label for error messages.
  final String label;

  const ArchComponent(this.id, {required this.label});

  /// A reverse lookup to find an enum value from its string [id].
  static ArchComponent fromId(String id) =>
      values.firstWhere((value) => value.id == id, orElse: () => ArchComponent.unknown);

  // --- Layer Composition Getters ---

  /// Returns a set of all components that belong to the Domain Layer.
  static Set<ArchComponent> get domainLayer => {
    entity,
    contract,
    usecase,
  };

  /// Returns a set of all components that belong to the Data Layer.
  static Set<ArchComponent> get dataLayer => {
    model,
    repository,
    source,
    sourceImplementation,
  };

  /// Returns a set of all components that belong to the Presentation Layer.
  static Set<ArchComponent> get presentationLayer => {
    page,
    widget,
    manager,
    event,
    eventImplementation,
    state,
    stateImplementation,
  };
}
