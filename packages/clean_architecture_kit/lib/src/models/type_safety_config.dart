// lib/src/models/type_safety_config.dart

import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';

class TypeSafetyConfig {
  final List<String> returnTypeNames;
  final List<String> importPaths;
  final List<String> applyTo;

  const TypeSafetyConfig({
    required this.returnTypeNames,
    required this.importPaths,
    required this.applyTo,
  });

  factory TypeSafetyConfig.fromMap(Map<String, dynamic> map) {
    return TypeSafetyConfig(
      returnTypeNames: map.getList('return_type_name'),
      importPaths: map.getList('import_path'),
      applyTo: map.getList('apply_to'),
    );
  }
}
