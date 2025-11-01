/// {@template data_source}
/// A base class for all data sources.
///
/// Data sources are responsible for retrieving data from a specific source,
/// such as a remote API or a local database.
/// {@endtemplate}
abstract interface class DataSource {
  /// {@macro data_source}
  const DataSource();
}
