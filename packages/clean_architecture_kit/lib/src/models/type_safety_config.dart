// lib/src/models/type_safety_config.dart

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
      returnTypeNames: (map['return_type_name'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      importPaths: (map['import_path'] as List<dynamic>? ?? []).whereType<String>().toList(),
      applyTo: (map['apply_to'] as List<dynamic>? ?? []).whereType<String>().toList(),
    );
  }
}
