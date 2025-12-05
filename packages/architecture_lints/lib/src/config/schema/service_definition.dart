import 'package:architecture_lints/src/config/constants/config_keys.dart';
import 'package:architecture_lints/src/utils/map_extensions.dart';
import 'package:meta/meta.dart';

@immutable
class ServiceDefinition {
  final List<String> types; // e.g. ['GetIt', 'Injector']
  final List<String> identifiers; // e.g. ['getIt', 'sl']
  final String? import;

  const ServiceDefinition({
    this.types = const [],
    this.identifiers = const [],
    this.import,
  });

  factory ServiceDefinition.fromMap(Map<dynamic, dynamic> map) {
    return ServiceDefinition(
      types: map.getStringList(ConfigKeys.service.type),
      identifiers: map.getStringList(ConfigKeys.service.identifier),
      import: map.tryGetString(ConfigKeys.service.import),
    );
  }
}