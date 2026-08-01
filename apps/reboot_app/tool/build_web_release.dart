import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const String _cacheNamePlaceholder = '@@CACHE_NAME@@';
const String _precachePathsPlaceholder = '@@PRECACHE_PATHS@@';
const String _workerFileName = 'reboot_service_worker.js';
const String _legacyWorkerFileName = 'flutter_service_worker.js';

Future<void> main(List<String> arguments) async {
  final prepareOnly = arguments.contains('--prepare-only');
  final projectDirectory = Directory.current.absolute;

  if (!File(
    '${projectDirectory.path}${Platform.pathSeparator}pubspec.yaml',
  ).existsSync()) {
    throw StateError('Run this command from the apps/reboot_app directory.');
  }

  if (!prepareOnly) {
    await _buildFlutterWeb(projectDirectory);
  }

  final prepared = await prepareWebRelease(
    buildDirectory: Directory(
      '${projectDirectory.path}${Platform.pathSeparator}build'
      '${Platform.pathSeparator}web',
    ),
    workerTemplate: File(
      '${projectDirectory.path}${Platform.pathSeparator}tool'
      '${Platform.pathSeparator}reboot_service_worker.template.js',
    ),
  );

  stdout.writeln(
    'Prepared ${prepared.assetPaths.length} offline shell assets in '
    '${prepared.cacheName}.',
  );
}

Future<void> _buildFlutterWeb(Directory projectDirectory) async {
  final executable = Platform.isWindows ? 'flutter.bat' : 'flutter';
  final process = await Process.start(
    executable,
    const [
      'build',
      'web',
      '--release',
      '--no-web-resources-cdn',
      '--no-wasm-dry-run',
    ],
    workingDirectory: projectDirectory.path,
    mode: ProcessStartMode.inheritStdio,
    runInShell: Platform.isWindows,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw ProcessException(
      executable,
      const [
        'build',
        'web',
        '--release',
        '--no-web-resources-cdn',
        '--no-wasm-dry-run',
      ],
      'Flutter Web build failed.',
      exitCode,
    );
  }
}

Future<PreparedWebRelease> prepareWebRelease({
  required Directory buildDirectory,
  required File workerTemplate,
}) async {
  if (!buildDirectory.existsSync()) {
    throw StateError('Missing Web build directory: ${buildDirectory.path}');
  }
  if (!workerTemplate.existsSync()) {
    throw StateError('Missing service worker template: ${workerTemplate.path}');
  }

  final legacyWorker = File(
    '${buildDirectory.path}${Platform.pathSeparator}$_legacyWorkerFileName',
  );
  if (legacyWorker.existsSync()) {
    await legacyWorker.delete();
  }

  final files = await buildDirectory
      .list(recursive: true, followLinks: false)
      .where((entity) => entity is File)
      .cast<File>()
      .where((file) => !_isExcluded(file, buildDirectory))
      .toList();
  files.sort(
    (left, right) => _relativePath(
      left,
      buildDirectory,
    ).compareTo(_relativePath(right, buildDirectory)),
  );

  final assetPaths = files
      .map((file) => _relativePath(file, buildDirectory))
      .toList(growable: false);
  _verifyRequiredAssets(assetPaths);

  final fingerprint = BytesBuilder(copy: false);
  for (var index = 0; index < files.length; index += 1) {
    fingerprint
      ..add(utf8.encode(assetPaths[index]))
      ..addByte(0)
      ..add(await files[index].readAsBytes())
      ..addByte(0);
  }
  final digest = sha256.convert(fingerprint.takeBytes()).toString();
  final cacheName = 'reboot-shell-${digest.substring(0, 20)}';

  final template = await workerTemplate.readAsString();
  if (!template.contains(_cacheNamePlaceholder) ||
      !template.contains(_precachePathsPlaceholder)) {
    throw StateError('The service worker template is missing placeholders.');
  }

  final workerSource = template
      .replaceAll(_cacheNamePlaceholder, cacheName)
      .replaceAll(
        _precachePathsPlaceholder,
        const JsonEncoder.withIndent('  ').convert(assetPaths),
      );
  final worker = File(
    '${buildDirectory.path}${Platform.pathSeparator}$_workerFileName',
  );
  await worker.writeAsString('$workerSource\n', flush: true);

  return PreparedWebRelease(
    cacheName: cacheName,
    assetPaths: assetPaths,
    worker: worker,
  );
}

bool _isExcluded(File file, Directory buildDirectory) {
  final path = _relativePath(file, buildDirectory);
  final segments = path.split('/');
  return segments.any((segment) => segment.startsWith('.')) ||
      path == _workerFileName ||
      path == _legacyWorkerFileName ||
      path.endsWith('.symbols') ||
      path.startsWith('canvaskit/experimental_webparagraph/') ||
      path.startsWith('canvaskit/skwasm') ||
      path.startsWith('canvaskit/wimp');
}

String _relativePath(File file, Directory buildDirectory) {
  final root = buildDirectory.absolute.path;
  final absolute = file.absolute.path;
  if (!absolute.startsWith('$root${Platform.pathSeparator}')) {
    throw StateError('File is outside the Web build: $absolute');
  }
  return absolute
      .substring(root.length + 1)
      .replaceAll(Platform.pathSeparator, '/');
}

void _verifyRequiredAssets(List<String> assetPaths) {
  const required = {
    'flutter_bootstrap.js',
    'index.html',
    'main.dart.js',
    'manifest.json',
  };
  final missing = required.difference(assetPaths.toSet());
  if (missing.isNotEmpty) {
    throw StateError(
      'Incomplete Flutter Web build: missing ${missing.join(', ')}',
    );
  }
}

final class PreparedWebRelease {
  const PreparedWebRelease({
    required this.cacheName,
    required this.assetPaths,
    required this.worker,
  });

  final String cacheName;
  final List<String> assetPaths;
  final File worker;
}
