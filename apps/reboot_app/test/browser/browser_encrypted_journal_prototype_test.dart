@TestOn('browser')
library;

import 'dart:convert';

import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';
import 'package:reboot_app/web_storage/encrypted_event_envelope.dart';
import 'package:reboot_app/web_storage/encrypted_projection_snapshot.dart';
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

String _databaseName(String suffix) =>
    'reboot-test-$suffix-${DateTime.now().microsecondsSinceEpoch}';
