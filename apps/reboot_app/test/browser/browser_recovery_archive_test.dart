@TestOn('browser')
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';
import 'package:reboot_app/web_storage/browser_local_event_journal.dart';
import 'package:reboot_app/web_storage/browser_recovery_archive.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
import 'package:test/test.dart';

void main() {
  final codec = EventRecordJsonCodec();

  test('matches the RBP1 AES-GCM cross-platform fixture', () async {
    final source = await _profile('portable-fixture', <EventRecord>[
      _householdEvent(),
    ]);
    addTearDown(source.delete);
    final archives = BrowserRecoveryArchiveService(
      randomBytes: (length) =>
          Uint8List.fromList(List<int>.filled(length, length == 32 ? 77 : 78)),
    );

    final prepared = await archives.prepare(source.service);

    expect(
      sha256.convert(prepared.bytes).toString(),
      'cf31524ea1a0fab1588a434b670d0f2cf518036a42f069c245e8887374aef30c',
    );
  });

  test(
    'exports opaque bytes and restores a complete validated journal',
    () async {
      final source = await _profile('source', <EventRecord>[_householdEvent()]);
      final destination = await _profile('destination', const <EventRecord>[]);
      addTearDown(() async {
        await source.delete();
        await destination.delete();
      });
      final archives = BrowserRecoveryArchiveService();

      final prepared = await archives.prepare(source.service);
      final persistedText = utf8.decode(prepared.bytes);
      expect(persistedText, isNot(contains('sharedMainAccount')));
      expect(persistedText, isNot(contains('Europe/Paris')));
      expect(persistedText, isNot(contains('household.created')));
      expect(prepared.recoveryCode, startsWith('RBP1.'));

      await archives.restore(
        destination: destination.service,
        archiveBytes: prepared.bytes,
        recoveryCode: prepared.recoveryCode,
      );
      final restored = await destination.service.readJournalSnapshot();
      expect(restored, hasLength(1));
      expect(
        codec.encode(restored.single.event),
        codec.encode(_householdEvent()),
      );
    },
  );

  test('rejects a wrong recovery code without modifying destination', () async {
    final source = await _profile('wrong-code-source', <EventRecord>[
      _householdEvent(),
    ]);
    final destination = await _profile(
      'wrong-code-destination',
      const <EventRecord>[],
    );
    addTearDown(() async {
      await source.delete();
      await destination.delete();
    });
    final archives = BrowserRecoveryArchiveService();
    final prepared = await archives.prepare(source.service);
    final wrongCode =
        '${prepared.recoveryCode.substring(0, 5)}A'
        '${prepared.recoveryCode.substring(6)}';

    await expectLater(
      archives.restore(
        destination: destination.service,
        archiveBytes: prepared.bytes,
        recoveryCode: wrongCode,
      ),
      throwsA(
        isA<BrowserRecoveryArchiveException>().having(
          (error) => error.reason,
          'reason',
          BrowserRecoveryArchiveFailureReason.archiveInvalid,
        ),
      ),
    );
    await expectLater(
      archives.restore(
        destination: destination.service,
        archiveBytes: prepared.bytes,
        recoveryCode: 'not-a-recovery-code',
      ),
      throwsA(
        isA<BrowserRecoveryArchiveException>().having(
          (error) => error.reason,
          'reason',
          BrowserRecoveryArchiveFailureReason.invalidRecoveryCode,
        ),
      ),
    );
    expect(await destination.service.readJournalSnapshot(), isEmpty);
  });

  test(
    'rejects authenticated corruption without modifying destination',
    () async {
      final source = await _profile('corrupt-source', <EventRecord>[
        _householdEvent(),
      ]);
      final destination = await _profile(
        'corrupt-destination',
        const <EventRecord>[],
      );
      addTearDown(() async {
        await source.delete();
        await destination.delete();
      });
      final archives = BrowserRecoveryArchiveService();
      final prepared = await archives.prepare(source.service);
      final outer =
          jsonDecode(utf8.decode(prepared.bytes)) as Map<String, Object?>;
      final ciphertext = outer['ciphertext']! as String;
      outer['ciphertext'] =
          '${ciphertext.startsWith('A') ? 'B' : 'A'}${ciphertext.substring(1)}';

      await expectLater(
        archives.restore(
          destination: destination.service,
          archiveBytes: Uint8List.fromList(utf8.encode(jsonEncode(outer))),
          recoveryCode: prepared.recoveryCode,
        ),
        throwsA(
          isA<BrowserRecoveryArchiveException>().having(
            (error) => error.reason,
            'reason',
            BrowserRecoveryArchiveFailureReason.archiveInvalid,
          ),
        ),
      );
      expect(await destination.service.readJournalSnapshot(), isEmpty);
    },
  );

  test('refuses to merge an archive into a non-empty profile', () async {
    final source = await _profile('nonempty-source', <EventRecord>[
      _householdEvent(),
    ]);
    final destination = await _profile('nonempty-destination', <EventRecord>[
      _householdEvent(),
    ]);
    addTearDown(() async {
      await source.delete();
      await destination.delete();
    });
    final archives = BrowserRecoveryArchiveService();
    final prepared = await archives.prepare(source.service);

    await expectLater(
      archives.restore(
        destination: destination.service,
        archiveBytes: prepared.bytes,
        recoveryCode: prepared.recoveryCode,
      ),
      throwsA(
        isA<BrowserRecoveryArchiveException>().having(
          (error) => error.reason,
          'reason',
          BrowserRecoveryArchiveFailureReason.localProfileNotEmpty,
        ),
      ),
    );
    expect(await destination.service.readJournalSnapshot(), hasLength(1));
  });
}

final class _TestProfile {
  const _TestProfile({required this.databaseName, required this.service});

  final String databaseName;
  final LocalRebootService service;

  Future<void> delete() async {
    await service.close();
    await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
      databaseName,
    );
    BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
  }
}

Future<_TestProfile> _profile(String label, List<EventRecord> events) async {
  final databaseName =
      'reboot-recovery-$label-${DateTime.now().microsecondsSinceEpoch}';
  final journal = await BrowserLocalEventJournal.open(
    databaseName: databaseName,
  );
  if (events.isNotEmpty) await journal.appendAll(events);
  return _TestProfile(
    databaseName: databaseName,
    service: await LocalRebootService.restore(journal: journal),
  );
}

EventRecord _householdEvent() {
  return EventRecord(
    id: EventId('01960001-1111-7111-8111-000000000001'),
    recordedAtUtc: DateTime.utc(2026, 4, 1, 10),
    businessDate: LocalDate(2026, 4, 1),
    target: EntityReference(
      kind: EntityKind.household,
      id: EntityId('01960002-2222-7222-8222-000000000001'),
    ),
    payload: HouseholdCreatedPayload(
      householdKind: HouseholdKind.sharedMainAccount,
      currency: Currency.eur,
      initialCyclePolicy: CyclePolicy(
        version: 1,
        effectiveFrom: LocalDate(2026, 4, 4),
        anchorWeekday: Weekday.saturday,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      ),
    ),
  );
}
