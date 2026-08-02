@TestOn('browser')
library;

import 'dart:convert';

import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';
import 'package:reboot_app/web_storage/encrypted_event_envelope.dart';
import 'package:reboot_app/web_storage/encrypted_projection_snapshot.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
import 'package:test/test.dart';

void main() {
  test('stores only authenticated ciphertext and survives reopening', () async {
    final databaseName = _databaseName('roundtrip');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });

    final first = _event(1, '{"secretLabel":"synthetic-groceries"}');
    final second = _event(2, '{"secretLabel":"synthetic-cinema"}');
    expect(journal.keyIsNonExtractable, isTrue);
    expect(await journal.keyExportIsRejectedForTesting(), isTrue);
    expect(await journal.append(first), BigInt.one);
    expect(await journal.append(second), BigInt.two);

    final persisted = await journal.inspectEncryptedRecordsForTesting();
    final storedText = jsonEncode(persisted);
    expect(storedText, isNot(contains('synthetic-groceries')));
    expect(storedText, isNot(contains('synthetic-cinema')));
    expect(storedText, contains('ciphertext'));
    expect(storedText, contains('nonce'));

    journal.close();
    final reopened = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    expect(reopened.keyIsNonExtractable, isTrue);
    expect(await reopened.readAll(), <WebPrototypePlainEvent>[first, second]);
    reopened.close();
  });

  test('is idempotent by UUID and rejects conflicting content', () async {
    final databaseName = _databaseName('duplicate');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final event = _event(3, '{"value":1}');

    expect(await journal.append(event), BigInt.one);
    expect(await journal.append(event), BigInt.one);
    expect(
      () => journal.append(
        WebPrototypePlainEvent(
          eventId: event.eventId,
          eventType: event.eventType,
          schemaVersion: event.schemaVersion,
          payloadJson: '{"value":2}',
        ),
      ),
      throwsA(isA<WebJournalEventConflictException>()),
    );
    expect(await journal.readAll(), <WebPrototypePlainEvent>[event]);
  });

  test('atomically appends batches with consecutive positions', () async {
    final databaseName = _databaseName('batch');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final first = _event(20, '{"value":1}');
    final second = _event(21, '{"value":2}');

    expect(
      await journal.appendAll(<WebPrototypePlainEvent>[first, second, first]),
      <BigInt>[BigInt.one, BigInt.two, BigInt.one],
    );
    expect(await journal.readAll(), <WebPrototypePlainEvent>[first, second]);
  });

  test('rejects an in-batch UUID conflict without writing siblings', () async {
    final databaseName = _databaseName('batch-conflict');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final original = _event(22, '{"value":1}');
    final conflicting = WebPrototypePlainEvent(
      eventId: original.eventId,
      eventType: original.eventType,
      schemaVersion: original.schemaVersion,
      payloadJson: '{"value":2}',
    );

    await expectLater(
      journal.appendAll(<WebPrototypePlainEvent>[
        _event(23, '{"sibling":true}'),
        original,
        conflicting,
      ]),
      throwsA(isA<WebJournalEventConflictException>()),
    );
    expect(await journal.readAll(), isEmpty);
  });

  test('rejects an existing UUID conflict without writing siblings', () async {
    final databaseName = _databaseName('existing-batch-conflict');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final original = _event(24, '{"value":1}');
    await journal.append(original);

    await expectLater(
      journal.appendAll(<WebPrototypePlainEvent>[
        _event(25, '{"sibling":true}'),
        WebPrototypePlainEvent(
          eventId: original.eventId,
          eventType: original.eventType,
          schemaVersion: original.schemaVersion,
          payloadJson: '{"value":2}',
        ),
      ]),
      throwsA(isA<WebJournalEventConflictException>()),
    );
    expect(await journal.readAll(), <WebPrototypePlainEvent>[original]);
  });

  test('serializes concurrent writers without duplicate positions', () async {
    final databaseName = _databaseName('concurrent');
    final firstJournal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    final secondJournal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      firstJournal.close();
      secondJournal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final first = _event(8, '{"writer":1}');
    final second = _event(9, '{"writer":2}');

    final positions = await Future.wait(<Future<BigInt>>[
      firstJournal.append(first),
      secondJournal.append(second),
    ]);

    expect(positions.toSet(), <BigInt>{BigInt.one, BigInt.two});
    expect((await firstJournal.readAll()).toSet(), <WebPrototypePlainEvent>{
      first,
      second,
    });
  });

  test('serializes concurrent batches without partial interleaving', () async {
    final databaseName = _databaseName('concurrent-batches');
    final firstJournal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    final secondJournal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      firstJournal.close();
      secondJournal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final firstBatch = <WebPrototypePlainEvent>[
      _event(26, '{"writer":1,"item":1}'),
      _event(27, '{"writer":1,"item":2}'),
    ];
    final secondBatch = <WebPrototypePlainEvent>[
      _event(28, '{"writer":2,"item":1}'),
      _event(29, '{"writer":2,"item":2}'),
    ];

    final positions = await Future.wait(<Future<List<BigInt>>>[
      firstJournal.appendAll(firstBatch),
      secondJournal.appendAll(secondBatch),
    ]);

    expect(
      positions.map((batch) => batch.last - batch.first),
      everyElement(BigInt.one),
    );
    expect(positions.expand((batch) => batch).toSet(), <BigInt>{
      BigInt.one,
      BigInt.two,
      BigInt.from(3),
      BigInt.from(4),
    });
    expect(await firstJournal.readAll(), hasLength(4));
  });

  test('rolls back sibling writes when an IndexedDB request fails', () async {
    final databaseName = _databaseName('rollback');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final first = _event(10, '{"value":1}');
    final second = _event(11, '{"value":2}');
    expect(await journal.append(first), BigInt.one);

    await expectLater(
      journal.forceTransactionFailureForTesting(),
      throwsA(isA<WebJournalStorageException>()),
    );

    expect(await journal.append(second), BigInt.two);
    expect(await journal.readAll(), <WebPrototypePlainEvent>[first, second]);
  });

  test('rejects altered ciphertext before decoding the event', () async {
    final databaseName = _databaseName('corruption');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    await journal.append(_event(4, '{"value":"confidential"}'));
    await journal.corruptCiphertextForTesting(BigInt.one);

    expect(
      () => journal.readAll(),
      throwsA(isA<WebJournalIntegrityException>()),
    );
    expect(
      () => journal.readAfter(BigInt.zero),
      throwsA(isA<WebJournalIntegrityException>()),
    );
  });

  test('authenticates clear routing metadata with the ciphertext', () async {
    final databaseName = _databaseName('header-corruption');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    await journal.append(_event(7, '{"value":"confidential"}'));
    await journal.corruptEventIdForTesting(
      BigInt.one,
      '018f1f3a-7b1c-7a2d-8e3f-999999999999',
    );

    expect(
      () => journal.readAll(),
      throwsA(isA<WebJournalIntegrityException>()),
    );
  });

  test('rejects a journal tail inconsistent with its entries', () async {
    final databaseName = _databaseName('tail-corruption');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    await journal.append(_event(12, '{"value":"confidential"}'));
    await journal.corruptLastPositionForTesting('2');

    expect(
      () => journal.readAll(),
      throwsA(isA<WebJournalIntegrityException>()),
    );
  });

  test('rejects an envelope missing from the UUID index', () async {
    final databaseName = _databaseName('index-corruption');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final event = _event(13, '{"value":"confidential"}');
    await journal.append(event);
    await journal.deleteEventIdIndexForTesting(event.eventId);

    expect(
      () => journal.readAll(),
      throwsA(isA<WebJournalIntegrityException>()),
    );
  });

  test('missing key fails closed and is never regenerated', () async {
    final databaseName = _databaseName('key-loss');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    await journal.append(_event(5, '{"value":"confidential"}'));
    await journal.deleteKeyForTesting();
    journal.close();

    expect(
      () => BrowserEncryptedJournalPrototype.open(databaseName: databaseName),
      throwsA(isA<WebJournalKeyUnavailableException>()),
    );
  });

  test(
    'independent marker detects deletion of the IndexedDB database',
    () async {
      final databaseName = _databaseName('database-loss');
      final journal = await BrowserEncryptedJournalPrototype.open(
        databaseName: databaseName,
      );
      addTearDown(() async {
        journal.close();
        await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
          databaseName,
        );
        BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
      });
      await journal.append(_event(6, '{"value":"confidential"}'));
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );

      expect(
        () => BrowserEncryptedJournalPrototype.open(databaseName: databaseName),
        throwsA(isA<WebJournalKeyUnavailableException>()),
      );
    },
  );

  test('encrypts a replaceable snapshot anchored to the journal', () async {
    final databaseName = _databaseName('snapshot');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final first = _event(14, '{"value":"first"}');
    final second = _event(15, '{"value":"second"}');
    await journal.append(first);
    final snapshot = WebPrototypeProjectionSnapshot(
      journalPosition: BigInt.one,
      schemaVersion: 1,
      projectionJson: '{"secretRemainingMinorUnits":"12345"}',
    );

    await journal.writeProjectionSnapshot(snapshot);
    final persisted = await journal.inspectEncryptedSnapshotForTesting();
    expect(persisted, isNotNull);
    expect(jsonEncode(persisted), isNot(contains('secretRemainingMinorUnits')));
    expect(jsonEncode(persisted), isNot(contains('12345')));

    await journal.append(second);
    final restored = await journal.readProjectionSnapshot();
    expect(restored, isNotNull);
    expect(restored!.journalPosition, BigInt.one);
    expect(restored.schemaVersion, 1);
    expect(restored.projectionJson, snapshot.projectionJson);
    expect(
      await journal.readAfter(restored.journalPosition),
      <WebPrototypePlainEvent>[second],
    );
    expect(await journal.readAfter(BigInt.two), isEmpty);
    expect(await journal.readAfter(BigInt.zero), <WebPrototypePlainEvent>[
      first,
      second,
    ]);
    expect(await journal.readAll(), <WebPrototypePlainEvent>[first, second]);
  });

  test(
    'resumes a real expense projection from an encrypted snapshot',
    () async {
      final databaseName = _databaseName('expense-projection-snapshot');
      final journal = await BrowserEncryptedJournalPrototype.open(
        databaseName: databaseName,
      );
      addTearDown(() async {
        journal.close();
        await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
          databaseName,
        );
        BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
      });
      final recordCodec = EventRecordJsonCodec();
      final snapshotCodec = ExpenseLedgerSnapshotCodec();
      final recorded = _domainExpenseEvent(
        31,
        ExpenseRecordedPayload(
          amount: Money.fromMinorUnits(15000, Currency.eur),
          label: 'courses-confidentielles',
          cycleAssignment: ExpenseCycleAssignment(
            cycleStart: LocalDate(2026, 8, 1),
            policyVersion: 1,
            timeZone: IanaTimeZoneId('Europe/Paris'),
          ),
        ),
      );
      final nature = _domainExpenseEvent(
        32,
        const ExpenseNatureSetPayload(nature: ExpenseNature.necessary),
      );
      await journal.append(_plainDomainEvent(recorded, recordCodec));
      final prefix = ExpenseLedger.replay([
        LocalJournalEntry(position: LocalJournalPosition(1), event: recorded),
      ]);
      final projectionJson = snapshotCodec.encode(prefix);
      await journal.writeProjectionSnapshot(
        WebPrototypeProjectionSnapshot(
          journalPosition: BigInt.one,
          schemaVersion: ExpenseLedgerSnapshotCodec.schemaVersion,
          projectionJson: projectionJson,
        ),
      );

      await journal.append(_plainDomainEvent(nature, recordCodec));
      final persisted = jsonEncode(
        await journal.inspectEncryptedSnapshotForTesting(),
      );
      expect(persisted, isNot(contains('courses-confidentielles')));
      final snapshot = await journal.readProjectionSnapshot();
      expect(snapshot, isNotNull);
      var resumed = snapshotCodec.decode(snapshot!.projectionJson);
      final suffix = await journal.readAfter(snapshot.journalPosition);
      for (var index = 0; index < suffix.length; index++) {
        resumed = resumed.apply(
          LocalJournalEntry(
            position: LocalJournalPosition.fromBigInt(
              snapshot.journalPosition + BigInt.from(index + 1),
            ),
            event: recordCodec.decode(suffix[index].payloadJson),
          ),
        );
      }
      final fullReplay = ExpenseLedger.replay([
        LocalJournalEntry(position: LocalJournalPosition(1), event: recorded),
        LocalJournalEntry(position: LocalJournalPosition(2), event: nature),
      ]);

      expect(snapshotCodec.encode(resumed), snapshotCodec.encode(fullReplay));
      expect(resumed.activeExpenses.single.nature, ExpenseNature.necessary);
    },
  );

  test('discards a corrupt snapshot without touching the journal', () async {
    final databaseName = _databaseName('snapshot-corruption');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    final event = _event(16, '{"value":"journal-remains"}');
    await journal.append(event);
    await journal.writeProjectionSnapshot(
      WebPrototypeProjectionSnapshot(
        journalPosition: BigInt.one,
        schemaVersion: 1,
        projectionJson: '{"derived":"discardable"}',
      ),
    );
    await journal.corruptSnapshotCiphertextForTesting();

    expect(await journal.readProjectionSnapshot(), isNull);
    expect(await journal.inspectEncryptedSnapshotForTesting(), isNull);
    expect(await journal.readAll(), <WebPrototypePlainEvent>[event]);
  });

  test('refuses to snapshot anything other than the current tail', () async {
    final databaseName = _databaseName('snapshot-position');
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });
    await journal.append(_event(17, '{"value":1}'));

    expect(
      () => journal.writeProjectionSnapshot(
        WebPrototypeProjectionSnapshot(
          journalPosition: BigInt.two,
          schemaVersion: 1,
          projectionJson: '{"derived":"future"}',
        ),
      ),
      throwsA(isA<WebJournalSnapshotPositionException>()),
    );
  });

  test('migrates a version-one journal without changing its event', () async {
    final databaseName = _databaseName('migration-v1-v2');
    final event = _event(18, '{"value":"legacy"}');
    await BrowserEncryptedJournalPrototype.createLegacyVersionOneForTesting(
      databaseName: databaseName,
      event: event,
    );
    final journal = await BrowserEncryptedJournalPrototype.open(
      databaseName: databaseName,
    );
    addTearDown(() async {
      journal.close();
      await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
        databaseName,
      );
      BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
    });

    expect(await journal.readAll(), <WebPrototypePlainEvent>[event]);
    await journal.writeProjectionSnapshot(
      WebPrototypeProjectionSnapshot(
        journalPosition: BigInt.one,
        schemaVersion: 1,
        projectionJson: '{"migrated":true}',
      ),
    );
    expect(
      (await journal.readProjectionSnapshot())?.projectionJson,
      '{"migrated":true}',
    );
  });
}

WebPrototypePlainEvent _event(int sequence, String payloadJson) {
  return WebPrototypePlainEvent(
    eventId: '018f1f3a-7b1c-7a2d-8e3f-${sequence.toString().padLeft(12, '0')}',
    eventType: 'prototype.synthetic',
    schemaVersion: 1,
    payloadJson: payloadJson,
  );
}

EventRecord _domainExpenseEvent(int sequence, EventPayload payload) {
  return EventRecord(
    id: EventId(
      '018f1f3a-7b1c-7a2d-8e3f-${sequence.toString().padLeft(12, '0')}',
    ),
    recordedAtUtc: DateTime.utc(2026, 8, 1, 10, 0, sequence),
    businessDate: LocalDate(2026, 8, 1),
    target: EntityReference(
      kind: EntityKind.expense,
      id: EntityId('018f2b8a-7d3c-7a1b-8c4d-000000000001'),
    ),
    payload: payload,
  );
}

WebPrototypePlainEvent _plainDomainEvent(
  EventRecord event,
  EventRecordJsonCodec codec,
) {
  return WebPrototypePlainEvent(
    eventId: event.id.value,
    eventType: event.eventType,
    schemaVersion: event.schemaVersion,
    payloadJson: codec.encode(event),
  );
}

String _databaseName(String suffix) =>
    'reboot-test-$suffix-${DateTime.now().microsecondsSinceEpoch}';
