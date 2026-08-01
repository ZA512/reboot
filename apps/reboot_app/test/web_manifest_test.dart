import 'dart:convert';
import 'dart:io';

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
  });
}
