// lib/src/utils/file/path_utils.dart

import 'package:analyzer/file_system/file_system.dart';
import 'package:architecture_lints/src/models/configs/architecture_config.dart';
import 'package:architecture_lints/src/models/configs/module_config.dart';
import 'package:architecture_lints/src/utils/extensions/string_extension.dart';
import 'package:architecture_lints/src/utils/nlp/naming_utils.dart';
import 'package:path/path.dart' as p;

/// A utility class providing static methods for file system path resolution.
class PathUtils {
  const PathUtils._();

  /// Walks up the directory tree from [fileAbsolutePath] to find the first
  /// directory containing a `pubspec.yaml` file using the given [resourceProvider].
  static String? findProjectRoot(String fileAbsolutePath, ResourceProvider resourceProvider) {
    if (fileAbsolutePath.isEmpty) return null;

    try {
      // Use the provider to get the folder abstraction
      var folder = resourceProvider.getFolder(p.dirname(fileAbsolutePath));

      // Safety max depth
      var depth = 0;
      const maxDepth = 50;

      while (depth < maxDepth) {
        // Check for pubspec.yaml using the provider
        if (folder.getChildAssumingFile('pubspec.yaml').exists) {
          return folder.path;
        }

        final parent = folder.parent;
        // If parent path is same as current, we reached root
        if (parent.path == folder.path) return null;

        folder = parent;
        depth++;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Calculates the absolute path to the correct `usecases` directory.
  static String? getUseCasesDirectoryPath(
    String repoPath,
    ArchitectureConfig config,
    ResourceProvider resourceProvider,
  ) {
    final projectRoot = findProjectRoot(repoPath, resourceProvider);
    final segments = _getRelativePathSegments(repoPath);

    if (projectRoot == null || segments == null) return null;

    final modules = config.modules;
    final layers = config.layers;
    final useCaseDirName = layers.domain.usecase.firstOrNull ?? 'usecases';

    final context = resourceProvider.pathContext;

    // Handle feature-first architecture
    if (modules.type == ModuleType.featureFirst &&
        segments.length >= 2 &&
        segments.first == modules.features) {
      final featureName = segments[1];
      return context.join(
        projectRoot,
        'lib',
        modules.features,
        featureName,
        modules.domain,
        useCaseDirName,
      );
    }

    // Handle layer-first architecture
    if (modules.type == ModuleType.layerFirst) {
      return context.join(projectRoot, 'lib', modules.domain, useCaseDirName);
    }

    return null;
  }

  /// Constructs the full, absolute file path for an expected use case file.
  static String? getUseCaseFilePath({
    required String methodName,
    required String repoPath,
    required ArchitectureConfig config,
    required ResourceProvider resourceProvider,
  }) {
    final useCaseDir = getUseCasesDirectoryPath(repoPath, config, resourceProvider);
    if (useCaseDir == null) return null;

    final useCaseClassName = NamingUtils.getExpectedUseCaseClassName(methodName, config);
    final useCaseFileName = '${useCaseClassName.toSnakeCase()}.dart';

    return resourceProvider.pathContext.join(useCaseDir, useCaseFileName);
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
