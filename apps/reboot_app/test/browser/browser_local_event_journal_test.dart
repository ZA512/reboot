@TestOn('browser')
library;

import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';
import 'package:reboot_app/web_storage/browser_local_event_journal.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
import 'package:test/test.dart';

void main() {
  final codec = EventRecordJsonCodec();

  test(
    'persists and replays complete domain events in one atomic batch',
    () async {
      final databaseName = _databaseName('real-events');
      final journal = await BrowserLocalEventJournal.open(
        databaseName: databaseName,
      );
      addTearDown(() => _delete(journal, databaseName));
      final first = _expense(1, label: 'Courses');
      final second = _expense(2, label: 'Cinéma');

      final appended = await journal.appendAll(<EventRecord>[first, second]);
      expect(appended.map((entry) => entry.position.exactValue), <BigInt>[
        BigInt.one,
        BigInt.two,
      ]);

      final replayed = await journal.readAll();
      expect(replayed.map((entry) => codec.encode(entry.event)), <String>[
        codec.encode(first),
        codec.encode(second),
      ]);
    },
  );

  test('returns the same position for an identical event UUID', () async {
    final databaseName = _databaseName('real-idempotence');
    final journal = await BrowserLocalEventJournal.open(
      databaseName: databaseName,
    );
    addTearDown(() => _delete(journal, databaseName));
    final event = _expense(3, label: 'Flûte');

    final entries = await journal.appendAll(<EventRecord>[event, event]);
    expect(entries.map((entry) => entry.position.exactValue), <BigInt>[
      BigInt.one,
      BigInt.one,
    ]);
    expect(await journal.readAll(), hasLength(1));
  });

  test('rejects a UUID conflict without appending its sibling', () async {
    final databaseName = _databaseName('real-conflict');
    final journal = await BrowserLocalEventJournal.open(
      databaseName: databaseName,
    );
    addTearDown(() => _delete(journal, databaseName));
    final original = _expense(4, label: 'Original');
    await journal.append(original);
    final conflicting = _expense(4, label: 'Différent');
    final sibling = _expense(5, label: 'Ne doit pas être écrit');

    await expectLater(
      journal.appendAll(<EventRecord>[sibling, conflicting]),
      throwsA(
        isA<JournalEventConflictException>().having(
          (error) => error.eventId,
          'eventId',
          conflicting.id,
        ),
      ),
    );
    final replayed = await journal.readAll();
    expect(replayed, hasLength(1));
    expect(codec.encode(replayed.single.event), codec.encode(original));
  });
}

Future<void> _delete(
  BrowserLocalEventJournal journal,
  String databaseName,
) async {
  await journal.close();
  await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(databaseName);
  BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
}

EventRecord _expense(int identity, {required String label}) {
  final suffix = identity.toString().padLeft(12, '0');
  return EventRecord(
    id: EventId('01960001-1111-7111-8111-$suffix'),
    recordedAtUtc: DateTime.utc(2026, 4, 4, 10, 0, identity),
    businessDate: LocalDate(2026, 4, 4),
    target: EntityReference(
      kind: EntityKind.expense,
      id: EntityId('01960002-2222-7222-8222-$suffix'),
    ),
    payload: ExpenseRecordedPayload(
      amount: Money.fromMinorUnits(4200 + identity, Currency.eur),
      label: label,
      cycleAssignment: ExpenseCycleAssignment(
        cycleStart: LocalDate(2026, 4, 4),
        policyVersion: 1,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      ),
    ),
  );
}

String _databaseName(String label) =>
    'reboot-real-$label-${DateTime.now().microsecondsSinceEpoch}';
