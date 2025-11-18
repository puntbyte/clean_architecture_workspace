import 'package:clean_architecture_lints/src/utils/config_keys.dart';
import 'package:clean_architecture_lints/src/utils/extensions/json_map_extension.dart';

part 'package:clean_architecture_lints/src/models/rules/location_rule.dart';

part 'package:clean_architecture_lints/src/models/details/location_detail.dart';

/// The parent configuration class for all dependency location rules.
class LocationsConfig {
  final List<LocationRule> rules;
  final Map<String, LocationRule> _ruleMap;

  LocationsConfig({required this.rules})
    : _ruleMap = {
        for (final rule in rules)
          for (final id in rule.on) id: rule,
      };

  /// Finds the specific rule for a given architectural component ID.
  LocationRule? ruleFor(String componentId) => _ruleMap[componentId];

  /// Factory that parses the `locations` block from YAML.
  factory LocationsConfig.fromMap(Map<String, dynamic> map) {
    final ruleList = map.asMapList(ConfigKey.root.locations);
    return LocationsConfig(
      rules: ruleList.map(LocationRule.fromMap).whereType<LocationRule>().toList(),
    );
  }
}
