// lib/src/utils/path_utils.dart

import 'dart:io';
import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/naming_utils.dart';
import 'package:clean_architecture_kit/src/utils/string_extension.dart';
import 'package:path/path.dart' as p;

/// A utility class providing static methods for path resolution and validation
/// based on the configured architecture.
class PathUtils {
  // A private constructor to prevent instantiation of this utility class.
  const PathUtils._();

  /// Finds the project root directory by searching upwards for a `pubspec.yaml` file.
  static String? findProjectRoot(String fileAbsolutePath) {
    var dir = Directory(p.dirname(fileAbsolutePath));
    while (true) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) return dir.path;
      if (p.equals(dir.parent.path, dir.path)) break; // Reached filesystem root
      dir = dir.parent;
    }
    return null;
  }

  /// Determines the absolute path of the `usecases` directory for a given repository file.
  static String? getUseCasesDirectoryPath(String repoPath, CleanArchitectureConfig config) {
    final projectRoot = findProjectRoot(repoPath);
    if (projectRoot == null) return null;

    // ▼▼▼ IMPROVED LOGIC ▼▼▼
    final normalized = p.normalize(repoPath);
    final segments = p.split(normalized);
    final libIndex = segments.lastIndexOf('lib');
    if (libIndex == -1) return null;
    // This robustly gets the path segments *after* the 'lib' directory
    final insideLibSegments = segments.sublist(libIndex + 1);
    // ▲▲▲ END IMPROVED LOGIC ▲▲▲

    final layerCfg = config.layers;
    final useCaseDirs = layerCfg.domainUseCasesPaths;
    if (useCaseDirs.isEmpty) return null;
    final defaultUseCaseDir = useCaseDirs.first;

    if (layerCfg.projectStructure == 'feature_first') {
      // We can now use the segments we already calculated
      if (insideLibSegments.length < 3 || insideLibSegments[0] != layerCfg.featuresRootPath) {
        return null;
      }
      final featureName = insideLibSegments[1];
      return p.join(
        projectRoot,
        'lib',
        layerCfg.featuresRootPath,
        featureName,
        'domain',
        defaultUseCaseDir,
      );
    } else {
      return p.join(projectRoot, 'lib', 'domain', defaultUseCaseDir);
    }
  }

  /// Determines the full, absolute path for a new use case file.
  static String? getUseCaseFilePath({
    required String methodName,
    required String repoPath,
    required CleanArchitectureConfig config,
  }) {
    final useCaseDir = getUseCasesDirectoryPath(repoPath, config);
    if (useCaseDir == null) return null;

    final useCaseClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);
    final useCaseFileName = '${useCaseClassName.toSnakeCase()}.dart';
    return p.join(useCaseDir, useCaseFileName);
  }

  /// Checks if a given absolute path points to a file inside a configured entity directory.
  static bool isPathInEntityDirectory(String path, CleanArchitectureConfig config) {
    final layerConfig = config.layers;
    final entityDirs = layerConfig.domainEntitiesPaths;
    if (entityDirs.isEmpty) return false;

    final normalizedPath = p.normalize(path);
    final segments = normalizedPath.split(p.separator);

    final domainDirName = layerConfig.projectStructure == 'layer_first'
        ? layerConfig.domainPath
        : 'domain';

    final domainIndex = segments.lastIndexOf(domainDirName);
    if (domainIndex == -1) return false;

    for (final entityDir in entityDirs) {
      final entityIndex = segments.lastIndexOf(entityDir);
      if (entityIndex > domainIndex) return true;
    }

    return false;
  }
}
