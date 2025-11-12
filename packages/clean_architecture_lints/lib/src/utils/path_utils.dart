// lib/src/utils/path_utils.dart
import 'dart:io';

import 'package:path/path.dart' as p;

/// A utility class providing static methods for path resolution.
class PathUtils {
  const PathUtils._();

  /// Finds the project root directory by searching upwards for a `pubspec.yaml` file.
  static String? findProjectRoot(String fileAbsolutePath) {
    var dir = Directory(p.dirname(fileAbsolutePath));
    while (true) {
      if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) return dir.path;
      if (p.equals(dir.parent.path, dir.path)) return null;
      dir = dir.parent;
    }
  }
}
