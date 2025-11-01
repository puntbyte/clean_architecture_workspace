/// {@template entity}
/// A base class for all entities in the application.
///
/// Entities represent the core business objects of the application and should
/// be independent of any specific framework or technology.
/// {@endtemplate}
abstract interface class Entity {
  /// {@macro entity}
  const Entity();
}
