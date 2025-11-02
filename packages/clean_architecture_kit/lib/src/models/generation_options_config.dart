// lib/src/models/generation_options_config.dart

import 'package:clean_architecture_kit/src/utils/json_map_extension.dart';

class AnnotationConfig {
  final String importPath;
  final String annotationText;

  const AnnotationConfig({required this.importPath, required this.annotationText});

  factory AnnotationConfig.fromMap(dynamic map) {
    if (map is! Map) return const AnnotationConfig(importPath: '', annotationText: '');

    final safeMap = Map<String, dynamic>.from(map);

    return AnnotationConfig(
      importPath: safeMap.getString('import_path'),
      annotationText: safeMap.getString('annotation_text'),
    );
  }
}

class GenerationOptionsConfig {
  final List<AnnotationConfig> useCaseAnnotations;

  const GenerationOptionsConfig({required this.useCaseAnnotations});

  factory GenerationOptionsConfig.fromMap(Map<String, dynamic> map) {
    final annotations = map['use_case_annotations'] as List<dynamic>? ?? [];

    return GenerationOptionsConfig(
      useCaseAnnotations: annotations.map(AnnotationConfig.fromMap).toList(),
    );
  }
}
