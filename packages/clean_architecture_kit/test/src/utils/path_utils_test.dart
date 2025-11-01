// test/path_utils_test.dart

import 'dart:io';

import 'package:clean_architecture_kit/src/models/clean_architecture_config.dart';
import 'package:clean_architecture_kit/src/utils/path_utils.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../helpers/test_data.dart';

void main() {
  late Directory tempProject;
  late String projectRoot;
  late String repoFilePath;

  setUp(() async {
    tempProject = await Directory.systemTemp.createTemp('path_utils_test_');
    projectRoot = tempProject.path;

    // create pubspec at project root so findProjectRoot can locate it
    final pubspec = File(p.join(projectRoot, 'pubspec.yaml'));
    await pubspec.writeAsString('name: example');

    // create a sample repository file path inside lib/features/feature_a/data/repositories
    final repoDir = Directory(
      p.join(projectRoot, 'lib', 'features', 'feature_a', 'data', 'repositories'),
    );
    await repoDir.create(recursive: true);
    final repoFile = File(p.join(repoDir.path, 'some_repo.dart'));
    await repoFile.writeAsString('// repo');

    // use absolute normalized path
    repoFilePath = p.normalize(repoFile.absolute.path);
  });

  tearDown(() async {
    try {
      if (await tempProject.exists()) {
        await tempProject.delete(recursive: true);
      }
    } catch (_) {}
  });

  // Helper that tries several path normalizations and collects diagnostics.
  String? tryGetUseCasesDirWithDiagnostics(
    String repoPath,
    CleanArchitectureConfig config,
    StringBuffer out,
  ) {
    final attempts = <String>[
      repoPath,
      p.normalize(repoPath),
      // Replace backslashes with forward slashes and normalize (helps on Windows)
      repoPath.replaceAll(r'\', '/'),
      repoPath.replaceAll('/', p.separator),
    ].map(p.normalize).toSet().toList();

    out
      ..writeln('--- getUseCasesDirectoryPath diagnostics ---')
      ..writeln('original repoPath: $repoPath');
    for (var i = 0; i < attempts.length; i++) {
      final attempt = attempts[i];
      out
        ..writeln('attempt[$i]: $attempt')
        ..writeln('  exists: ${File(attempt).existsSync()}');
      final normalized = p.normalize(attempt);
      final libMarker = p.join('lib', '');
      final libIndex = normalized.indexOf(libMarker);
      out
        ..writeln('  normalized: $normalized')
        ..writeln("  libMarker (p.join('lib','')): '$libMarker'")
        ..writeln('  libIndex: $libIndex');
      final projectRoot = PathUtils.findProjectRoot(attempt);
      out.writeln('  findProjectRoot for attempt -> ${projectRoot ?? "null"}');
      try {
        final res = PathUtils.getUseCasesDirectoryPath(attempt, config);
        out.writeln('  getUseCasesDirectoryPath returned: ${res ?? "null"}');
        if (res != null) return res;
      } catch (e, st) {
        out.writeln('  getUseCasesDirectoryPath threw: $e\n$st');
      }
      out.writeln('------------------------------------------------');
    }

    // Print some useful config state by accessing via dynamic (robust across model shapes)
    try {
      final layerConfig = config.layers;
      out
        ..writeln('Layer config snapshot:')
        ..writeln('  projectStructure: ${layerConfig.projectStructure}')
        ..writeln('  featuresRootPath: ${layerConfig.featuresRootPath}')
        ..writeln('  domainPath: ${layerConfig.domainPath}')
        ..writeln('  domainUseCasesPaths: ${layerConfig.domainUseCasesPaths}')
        ..writeln('  domainEntitiesPaths: ${layerConfig.domainEntitiesPaths}');
    } catch (e) {
      out.writeln('Could not introspect config.layers via dynamic: $e');
    }

    return null;
  }

  test('findProjectRoot finds the directory containing pubspec.yaml', () {
    final found = PathUtils.findProjectRoot(repoFilePath);
    expect(found, isNotNull, reason: 'findProjectRoot returned null for $repoFilePath');
    if (found != null) expect(p.normalize(found), p.normalize(projectRoot));
  });

  test('getUseCasesDirectoryPath returns expected usecase path (feature-first assumed)', () {
    final config = makeConfig();
    final diagnostics = StringBuffer();
    final useCaseDir = tryGetUseCasesDirWithDiagnostics(repoFilePath, config, diagnostics);

    if (useCaseDir == null) {
      // Fail with helpful diagnostics so you can paste the result here.
      fail(
        'getUseCasesDirectoryPath returned null.\n'
        'Diagnostics:\n$diagnostics\n'
        'Hints:\n'
        '- Check LayerConfig.fromMap keys (does it expect snake_case keys like layer_definitions/domain/use_cases?)\n'
        "- Check whether your project structure default is 'feature_first' or 'layer_first'.\n"
        '- Confirm the repository path contains a `lib` segment and the temporary pubspec.yaml is visible from that path.',
      );
    }

    // If we got a non-null value, assert it matches expected feature-first path.
    final expected = p.join(projectRoot, 'lib', 'features', 'feature_a', 'domain', 'usecases');
    expect(p.normalize(useCaseDir), p.normalize(expected));
  });

  test('getUseCaseFilePath constructs the expected filename from method name', () {
    final config = makeConfig();
    final diagnostics = StringBuffer();
    final useCaseDir = tryGetUseCasesDirWithDiagnostics(repoFilePath, config, diagnostics);

    if (useCaseDir == null) {
      fail(
        'getUseCaseFilePath pre-check failed because getUseCasesDirectoryPath returned null.\nDiagnostics:\n$diagnostics',
      );
    }

    final path = PathUtils.getUseCaseFilePath(
      methodName: 'fetchUser',
      repoPath: repoFilePath,
      config: config,
    );

    expect(path, isNotNull);
    if (path != null) {
      const expectedFileName = 'fetch_user_use_case.dart';
      expect(p.basename(path), expectedFileName);
      expect(p.dirname(path), p.normalize(useCaseDir));
    }
  });

  test('isPathInEntityDirectory returns true for a file inside domain entities', () async {
    final entityDir = Directory(
      p.join(projectRoot, 'lib', 'features', 'feature_a', 'domain', 'entities'),
    );
    await entityDir.create(recursive: true);
    final entityFile = File(p.join(entityDir.path, 'user_entity.dart'));
    await entityFile.writeAsString('// entity');

    final insidePath = p.normalize(entityFile.absolute.path);

    final config = makeConfig();
    final isInEntity = PathUtils.isPathInEntityDirectory(insidePath, config);
    expect(
      isInEntity,
      isTrue,
      reason: 'Expected file under domain/entities to be detected as entity path.',
    );
  });

  test('isPathInEntityDirectory returns false for a file outside domain entities', () async {
    final otherDir = Directory(p.join(projectRoot, 'lib', 'utils'));
    await otherDir.create(recursive: true);
    final otherFile = File(p.join(otherDir.path, 'helper.dart'));
    await otherFile.writeAsString('// helper');

    final config = makeConfig();
    final isInEntity = PathUtils.isPathInEntityDirectory(
      p.normalize(otherFile.absolute.path),
      config,
    );
    expect(isInEntity, isFalse);
  });
}
