import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/build_web_release.dart';

void main() {
  group('prepareWebRelease', () {
    late Directory temporaryDirectory;
    late Directory buildDirectory;
    late File workerTemplate;

    setUp(() async {
      temporaryDirectory = await Directory.systemTemp.createTemp(
        'reboot_web_release_test_',
      );
      buildDirectory = Directory(
        '${temporaryDirectory.path}${Platform.pathSeparator}build',
      )..createSync();
      workerTemplate =
          File(
            '${temporaryDirectory.path}${Platform.pathSeparator}worker.template.js',
          )..writeAsStringSync(
            "const cache = '@@CACHE_NAME@@';\n"
            'const assets = @@PRECACHE_PATHS@@;\n',
          );

      for (final path in const [
        'flutter_bootstrap.js',
        'index.html',
        'main.dart.js',
        'manifest.json',
        'assets/font.otf',
        'canvaskit/canvaskit.js',
        'canvaskit/canvaskit.js.symbols',
        'canvaskit/chromium/canvaskit.js',
        'canvaskit/skwasm.js',
      ]) {
        final file = File(
          '${buildDirectory.path}${Platform.pathSeparator}'
          '${path.replaceAll('/', Platform.pathSeparator)}',
        );
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('content:$path');
      }
      File(
        '${buildDirectory.path}${Platform.pathSeparator}'
        'flutter_service_worker.js',
      ).writeAsStringSync('legacy');
      File(
        '${buildDirectory.path}${Platform.pathSeparator}.last_build_id',
      ).writeAsStringSync('internal');
    });

    tearDown(() async {
      await temporaryDirectory.delete(recursive: true);
    });

    test(
      'creates a deterministic worker from deployable shell assets',
      () async {
        final first = await prepareWebRelease(
          buildDirectory: buildDirectory,
          workerTemplate: workerTemplate,
        );
        final firstSource = await first.worker.readAsString();

        expect(
          first.cacheName,
          matches(RegExp(r'^reboot-shell-[a-f0-9]{20}$')),
        );
        expect(first.assetPaths, orderedEquals([...first.assetPaths]..sort()));
        expect(first.assetPaths, contains('assets/font.otf'));
        expect(first.assetPaths, contains('canvaskit/canvaskit.js'));
        expect(first.assetPaths, contains('canvaskit/chromium/canvaskit.js'));
        expect(
          first.assetPaths,
          isNot(contains('canvaskit/canvaskit.js.symbols')),
        );
        expect(first.assetPaths, isNot(contains('canvaskit/skwasm.js')));
        expect(first.assetPaths, isNot(contains('flutter_service_worker.js')));
        expect(first.assetPaths, isNot(contains('.last_build_id')));
        expect(firstSource, contains(first.cacheName));
        expect(firstSource, contains('"main.dart.js"'));
        expect(firstSource, isNot(contains('@@CACHE_NAME@@')));
        expect(
          File(
            '${buildDirectory.path}${Platform.pathSeparator}'
            'flutter_service_worker.js',
          ).existsSync(),
          isFalse,
        );

        final second = await prepareWebRelease(
          buildDirectory: buildDirectory,
          workerTemplate: workerTemplate,
        );
        expect(second.cacheName, first.cacheName);
        expect(await second.worker.readAsString(), firstSource);
      },
    );

    test('changes the cache version when an asset changes', () async {
      final first = await prepareWebRelease(
        buildDirectory: buildDirectory,
        workerTemplate: workerTemplate,
      );
      File(
        '${buildDirectory.path}${Platform.pathSeparator}main.dart.js',
      ).writeAsStringSync('changed');

      final second = await prepareWebRelease(
        buildDirectory: buildDirectory,
        workerTemplate: workerTemplate,
      );

      expect(second.cacheName, isNot(first.cacheName));
    });

    test('refuses an incomplete Flutter build', () async {
      File(
        '${buildDirectory.path}${Platform.pathSeparator}main.dart.js',
      ).deleteSync();

      await expectLater(
        prepareWebRelease(
          buildDirectory: buildDirectory,
          workerTemplate: workerTemplate,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('main.dart.js'),
          ),
        ),
      );
    });
  });

  test('the production worker never caches arbitrary application traffic', () {
    final template = File(
      '${Directory.current.path}${Platform.pathSeparator}tool'
      '${Platform.pathSeparator}reboot_service_worker.template.js',
    ).readAsStringSync();

    expect(template, contains("request.method !== 'GET'"));
    expect(template, contains('requestUrl.origin !== self.location.origin'));
    expect(template, contains('!REBOOT_SHELL_URLS.has(requestUrl.href)'));
    expect(template, isNot(contains('cache.put(')));
  });
}
