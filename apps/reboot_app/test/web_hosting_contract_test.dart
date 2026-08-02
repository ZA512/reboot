import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/web_hosting_contract.dart';

void main() {
  late String productionSource;

  setUpAll(() {
    productionSource = File('web/_headers').readAsStringSync();
  });

  test('the production hosting contract is complete and strict', () {
    final contract = WebHostingContract.parse(productionSource);

    expect(contract.validate, returnsNormally);
    expect(
      contract.headersFor('/index.html')['cache-control'],
      'no-cache, no-store, must-revalidate',
    );
    expect(
      contract.headersFor('/index.html')['content-security-policy'],
      contains("script-src 'self' 'wasm-unsafe-eval'"),
    );
  });

  test('rejects a script policy that enables arbitrary evaluation', () {
    final weakened = productionSource.replaceFirst(
      "script-src 'self' 'wasm-unsafe-eval'",
      "script-src 'self' 'unsafe-eval'",
    );

    expect(
      () => WebHostingContract.parse(weakened).validate(),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects a missing cache rule for the service worker', () {
    final weakened = productionSource.replaceFirst(
      '/reboot_service_worker.js',
      '/removed_service_worker.js',
    );

    expect(
      () => WebHostingContract.parse(weakened).validate(),
      throwsA(isA<FormatException>()),
    );
  });
}
