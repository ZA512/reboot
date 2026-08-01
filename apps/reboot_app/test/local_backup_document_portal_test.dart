import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reboot_app/infrastructure/local_backup_document_portal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('reboot.test/local_backup');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test(
    'passes only explicit document operations through the platform channel',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return switch (call.method) {
          'saveBackup' => true,
          'pickBackup' => r'C:\private\selected.reboot-backup',
          'copyRecoveryCode' => null,
          _ => throw PlatformException(code: 'unexpected'),
        };
      });
      final portal = AndroidLocalBackupDocumentPortal(channel: channel);

      expect(
        await portal.save(
          source: File(r'C:\private\source.reboot-backup'),
          suggestedName: 'reboot-2026-08-01.reboot-backup',
        ),
        isTrue,
      );
      expect((await portal.pick())!.path, contains('selected.reboot-backup'));
      await portal.copySensitive('RB1.example-recovery-code');

      expect(calls.map((call) => call.method), [
        'saveBackup',
        'pickBackup',
        'copyRecoveryCode',
      ]);
      expect(
        (calls.first.arguments as Map<Object?, Object?>)['suggestedName'],
        'reboot-2026-08-01.reboot-backup',
      );
    },
  );

  test('maps native errors to sanitized categories', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) => throw PlatformException(code: 'backup_too_large'),
    );
    final portal = AndroidLocalBackupDocumentPortal(channel: channel);

    await expectLater(
      portal.pick(),
      throwsA(
        isA<LocalBackupDocumentException>().having(
          (error) => error.reason,
          'reason',
          LocalBackupDocumentFailureReason.tooLarge,
        ),
      ),
    );
  });
}
