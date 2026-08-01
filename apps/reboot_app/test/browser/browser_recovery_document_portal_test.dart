@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:reboot_app/web_storage/browser_recovery_document_portal.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  test('validates and copies bytes before starting a download', () async {
    Uint8List? downloaded;
    String? filename;
    final portal = BrowserRecoveryDocumentPortal(
      downloadTrigger: (bytes, suggestedName) async {
        downloaded = bytes;
        filename = suggestedName;
      },
    );
    final source = Uint8List.fromList(<int>[1, 2, 3]);

    await portal.save(
      bytes: source,
      suggestedName: 'reboot-2026-08-01.reboot-backup',
    );
    source[0] = 99;

    expect(downloaded, <int>[1, 2, 3]);
    expect(filename, 'reboot-2026-08-01.reboot-backup');
    await expectLater(
      portal.save(bytes: source, suggestedName: '../secret.reboot-backup'),
      throwsA(_failure(BrowserRecoveryDocumentFailureReason.invalidName)),
    );
    await expectLater(
      portal.save(bytes: Uint8List(0), suggestedName: 'reboot.reboot-backup'),
      throwsA(_failure(BrowserRecoveryDocumentFailureReason.invalidFile)),
    );
  });

  test(
    'reads one explicitly selected browser file into owned memory',
    () async {
      final source = Uint8List.fromList(<int>[4, 5, 6]);
      final file = web.File(
        <JSAny>[source.toJS].toJS,
        'renamed backup.reboot-backup',
        web.FilePropertyBag(type: 'application/octet-stream'),
      );
      final portal = BrowserRecoveryDocumentPortal(
        fileSelector: () async => file,
      );

      final selected = await portal.pick();
      source[0] = 99;

      expect(selected?.name, 'renamed backup.reboot-backup');
      expect(selected?.bytes, <int>[4, 5, 6]);
    },
  );

  test('treats picker cancellation as a normal null result', () async {
    final portal = BrowserRecoveryDocumentPortal(
      fileSelector: () async => null,
    );

    expect(await portal.pick(), isNull);
  });

  test('serializes document operations and reports busy immediately', () async {
    final selection = Completer<web.File?>();
    final portal = BrowserRecoveryDocumentPortal(
      fileSelector: () => selection.future,
      downloadTrigger: (bytes, suggestedName) async {},
    );

    final pending = portal.pick();
    await expectLater(
      portal.save(
        bytes: Uint8List.fromList(<int>[1]),
        suggestedName: 'reboot.reboot-backup',
      ),
      throwsA(_failure(BrowserRecoveryDocumentFailureReason.busy)),
    );
    selection.complete(null);
    expect(await pending, isNull);
  });

  test('copies only a syntactically valid RBP1 recovery code', () async {
    String? copied;
    final portal = BrowserRecoveryDocumentPortal(
      clipboardWriter: (value) async => copied = value,
    );
    const code = 'RBP1.AAAAAA.BBBBBB.CCCCCC.DDDDDD.EEEEEE.FFFFFF.GGGGGG.H';

    await portal.copySensitive('  $code\n');
    expect(copied, code);
    await expectLater(
      portal.copySensitive('RB1.not-portable'),
      throwsA(
        _failure(BrowserRecoveryDocumentFailureReason.invalidRecoveryCode),
      ),
    );
  });
}

TypeMatcher<BrowserRecoveryDocumentException> _failure(
  BrowserRecoveryDocumentFailureReason reason,
) {
  return isA<BrowserRecoveryDocumentException>().having(
    (error) => error.reason,
    'reason',
    reason,
  );
}
