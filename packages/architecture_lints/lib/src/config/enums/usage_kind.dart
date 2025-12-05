import 'package:collection/collection.dart';

enum UsageKind {
  /// Checking usage of global variables/static members (e.g. GetIt.I).
  access('access'),

  /// Checking class instantiation (e.g. new Repository()).
  instantiation('instantiation')
  ;

  final String yamlKey;

  const UsageKind(this.yamlKey);

  static UsageKind? fromKey(String? key) {
    return UsageKind.values.firstWhereOrNull((e) => e.yamlKey == key);
  }
}
