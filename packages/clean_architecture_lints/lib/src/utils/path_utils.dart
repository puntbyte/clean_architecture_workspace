// lib/src/utils/path_utils.dart

import 'dart:io';

import 'package:clean_architecture_lints/src/models/architecture_config.dart';
import 'package:clean_architecture_lints/src/models/module_config.dart';
import 'package:clean_architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:clean_architecture_lints/src/utils/naming_utils.dart';
import 'package:path/path.dart' as p;

/// A utility class providing static methods for file system path resolution.
class PathUtils {
  const PathUtils._();

  /// Walks up the directory tree from [fileAbsolutePath] to find the first
  /// directory containing a `pubspec.yaml` file.
  static String? findProjectRoot(String fileAbsolutePath) {
    var dir = Directory(p.dirname(fileAbsolutePath));
    while (true) {
      if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
        return dir.path;
      }
      // Stop if we reach the file system root.
      if (p.equals(dir.parent.path, dir.path)) return null;

      dir = dir.parent;
    }
  }

  /// Calculates the absolute path to the correct `usecases` directory based
  /// on the architecture type (feature-first vs. layer-first).
  static String? getUseCasesDirectoryPath(String repoPath, ArchitectureConfig config) {
    final projectRoot = findProjectRoot(repoPath);
    final segments = _getRelativePathSegments(repoPath);

    if (projectRoot == null || segments == null) return null;

    final modules = config.module;
    final layers = config.layer;
    final useCaseDir = layers.domain.usecase.firstOrNull ?? 'usecases';

    // Handle feature-first architecture
    if (modules.type == ModuleType.featureFirst &&
        segments.length >= 2 &&
        segments.first == modules.features) {
      final featureName = segments[1];
      return p.join(projectRoot, 'lib', modules.features, featureName, modules.domain, useCaseDir);
    }

    // Handle layer-first architecture
    if (modules.type == ModuleType.layerFirst) {
      return p.join(projectRoot, 'lib', modules.domain, useCaseDir);
    }

    return null;
  }

  /// Constructs the full, absolute file path for an expected use case file.
  static String? getUseCaseFilePath({
    required String methodName,
    required String repoPath,
    required ArchitectureConfig config,
  }) {
    final useCaseDir = getUseCasesDirectoryPath(repoPath, config);
    if (useCaseDir == null) return null;

    final useCaseClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);
    final useCaseFileName = '${useCaseClassName.toSnakeCase()}.dart';
    return p.join(useCaseDir, useCaseFileName);
  }

  /// Normalizes a path and returns the segments after the `lib/` directory.
  static List<String>? _getRelativePathSegments(String absolutePath) {
    final normalized = p.normalize(absolutePath);
    final segments = p.split(normalized);
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;
    return segments.sublist(libIndex + 1);
  }
}
