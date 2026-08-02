import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares the stable installable REBOOT web application identity', () {
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, Object?>;

    expect(manifest['id'], './');
    expect(manifest['start_url'], './');
    expect(manifest['scope'], './');
    expect(manifest['display'], 'standalone');
    expect(manifest['name'], 'REBOOT — Weekly Budget');
    expect(manifest['short_name'], 'REBOOT');
    expect(manifest['prefer_related_applications'], isFalse);

    final icons = (manifest['icons']! as List<Object?>)
        .cast<Map<String, Object?>>();
    expect(
      icons.map((icon) => icon['sizes']),
      containsAll(<String>['192x192', '512x512']),
    );
    expect(icons.where((icon) => icon['purpose'] == 'maskable'), hasLength(2));
    for (final icon in icons) {
      expect(File('web/${icon['src']}').existsSync(), isTrue);
    }
  });

  test('keeps the iPhone and service-worker bootstrap metadata', () {
    final index = File('web/index.html').readAsStringSync();
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    expect(index, contains('name="apple-mobile-web-app-capable"'));
    expect(index, contains('rel="apple-touch-icon"'));
    expect(index, contains('rel="manifest"'));
    expect(bootstrap, contains('reboot_service_worker.js'));
    expect(bootstrap, isNot(contains('flutter_service_worker.js')));
    expect(bootstrap, contains('fontFallbackBaseUrl'));
    expect(bootstrap, contains('font-fallback/'));
    expect(bootstrap, isNot(contains('fonts.gstatic.com')));
    expect(index, isNot(contains(RegExp(r'<script(?![^>]*\bsrc=)'))));
  });

  test('pins every self-hosted Flutter fallback font', () {
    const expectedDigests = {
      'web/font-fallback/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2':
          '35b02ca266b79eb4996590f15817425a1ce9ebf48f84471843233ff614656bf2',
      'web/font-fallback/notosanssymbols/v43/'
              'rP2up3q65FkAtHfwd-eIS2brbDN6gxP34F9jRRCe4W3gfQ8gb_VFRkzrbQ.woff2':
          '08202e258ea583254c036cff46a7077bb5af4f82c41a6c0a6775f6e44d99f1aa',
    };

    for (final entry in expectedDigests.entries) {
      final bytes = File(entry.key).readAsBytesSync();
      expect(sha256.convert(bytes).toString(), entry.value, reason: entry.key);
    }

    final actualPaths = Directory('web/font-fallback')
        .listSync(recursive: true)
        .whereType<File>()
        .map((file) => file.path.replaceAll(Platform.pathSeparator, '/'));
    expect(actualPaths, unorderedEquals(expectedDigests.keys));
  });
}
