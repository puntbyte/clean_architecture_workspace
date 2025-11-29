// lib/src/analysis/arch_component.dart

/// Represents the specific architectural component a file or class corresponds to.
///
/// The `snake_case` names of these enum values are the source of truth for keys
/// in the `analysis_options.yaml` configuration (e.g., `on: 'use_case'`).
enum ArchComponent {
  // --- Domain Components ---
  domain('domain', label: 'Domain'),
  entity('entity', label: 'Entity'),
  port('port', label: 'Port'),
  usecase('usecase', label: 'Usecase'),
  usecaseParameter('usecase.parameter', label: 'Usecase Parameter'),

  // --- Data Components ---
  data('data', label: 'Data'),
  model('model', label: 'Model'),
  source('source', label: 'Source'),
  sourceInterface('source.interface', label: 'Source Interface'),
  sourceImplementation('source.implementation', label: 'Source Implementation'),
  repository('repository', label: 'Repository (Implementation)'),

  // --- Presentation Components ---
  presentation('presentation', label: 'Presentation'),
  manager('manager', label: 'Manager (Bloc/Cubit)'),
  event('event', label: 'Event'),
  eventInterface('event.interface', label: 'Event Interface'),
  eventImplementation('event.implementation', label: 'Event Implementation'),
  state('state', label: 'State'),
  stateInterface('state.interface', label: 'State Interface'),
  stateImplementation('state.implementation', label: 'State Implementation'),
  widget('widget', label: 'Widget'),
  page('page', label: 'Page'),

  // --- Unknown Component ---
  unknown('unknown', label: 'Unknown')
  ;

  /// The `snake_case` identifier used in `analysis_options.yaml`.
  final String id;

  /// A user-friendly label for error messages.
  final String label;

  const ArchComponent(this.id, {required this.label});

  /// A reverse lookup to find an enum value from its string [id].
  static ArchComponent fromId(String id) {
    return values.firstWhere((value) => value.id == id, orElse: () => .unknown);
  }

  Set<ArchComponent> get children => switch (this) {
    .domain => {.entity, .port, .usecase},
    .usecase => {.usecaseParameter},

    .data => {.model, .repository, .source},
    .source => {.sourceInterface, .sourceImplementation},

    .presentation => {.page, .widget, .manager},
    .manager => {.event, .state},
    .event => {.eventInterface, .eventImplementation},
    .state => {.stateInterface, .stateImplementation},

    _ => {},
  };

  /// Recursively gets all direct and indirect children of this component.
  Set<ArchComponent> get allChildren {
    final collectedChildren = <ArchComponent>{};
    _collectChildren(this, collectedChildren);
    return collectedChildren;
  }

  /// A helper for the recursive traversal.
  static void _collectChildren(ArchComponent component, Set<ArchComponent> collected) {
    for (final child in component.children) {
      if (collected.add(child)) _collectChildren(child, collected);
    }
  }

  /// Returns the parent layer of this component.
  ///
  /// Implemented as a performant switch expression using dot shorthands.
  ArchComponent get layer => switch (this) {
    // Domain Layer & Components
    .domain || .entity || .port || .usecase || .usecaseParameter => .domain,

    // Data Layer & Components
    .data || .model || .repository || .source || .sourceInterface || .sourceImplementation => .data,

    // Presentation Layer & Components
    .presentation ||
    .page ||
    .widget ||
    .manager ||
    .event ||
    .eventInterface ||
    .eventImplementation ||
    .state ||
    .stateInterface ||
    .stateImplementation => .presentation,

    // Default
    _ => .unknown,
  };

  /// Returns a set of the top-level layers.
  /// Renamed to `layers` (plural) to avoid conflict with the instance getter.
  static Set<ArchComponent> get layers => {.domain, .data, .presentation};
}
