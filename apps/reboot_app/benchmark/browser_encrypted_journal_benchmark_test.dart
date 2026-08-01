@TestOn('browser')
library;

import 'dart:convert';

import 'package:reboot_app/web_storage/browser_encrypted_journal_prototype.dart';
import 'package:reboot_app/web_storage/browser_storage_durability.dart';
import 'package:reboot_app/web_storage/encrypted_event_envelope.dart';
import 'package:test/test.dart';

const int _eventCount = 300000;
const String _payload =
    '{"amountMinorUnits":"12345","currency":"EUR",'
    '"label":"synthetic-groceries","occurredOn":"2026-08-01",'
    '"nature":"essential","schemaPadding":"0123456789abcdef"}';

void main() {
  test(
    'measures encrypted append and complete authenticated replay',
    () async {
      final databaseName =
          'reboot-benchmark-${DateTime.now().microsecondsSinceEpoch}';
      var journal = await BrowserEncryptedJournalPrototype.open(
        databaseName: databaseName,
      );
      addTearDown(() async {
        journal.close();
        await BrowserEncryptedJournalPrototype.deleteDatabaseForTesting(
          databaseName,
        );
        BrowserEncryptedJournalPrototype.removeMarkerForTesting(databaseName);
      });

      final appendMicros = <int>[];
      final appendTotal = Stopwatch()..start();
      for (var sequence = 1; sequence <= _eventCount; sequence += 1) {
        final singleAppend = Stopwatch()..start();
        await journal.append(_event(sequence));
        singleAppend.stop();
        appendMicros.add(singleAppend.elapsedMicroseconds);
      }
      appendTotal.stop();

      journal.close();
      final reopen = Stopwatch()..start();
      journal = await BrowserEncryptedJournalPrototype.open(
        databaseName: databaseName,
      );
      reopen.stop();

      final replay = Stopwatch()..start();
      final events = await journal.readAll();
      replay.stop();
      expect(events, hasLength(_eventCount));
      expect(events.first.eventId, _event(1).eventId);
      expect(events.last.eventId, _event(_eventCount).eventId);

      appendMicros.sort();
      final durability = await inspectWebStorageDurability();
      final report = <String, Object>{
        'eventCount': _eventCount,
        'clearPayloadBytes': utf8.encode(_payload).length,
        'appendTotalMs': appendTotal.elapsedMilliseconds,
        'appendEventsPerSecond':
            _eventCount * 1000 / appendTotal.elapsedMilliseconds,
        'appendP50Ms': _percentile(appendMicros, 0.50) / 1000,
        'appendP95Ms': _percentile(appendMicros, 0.95) / 1000,
        'appendP99Ms': _percentile(appendMicros, 0.99) / 1000,
        'appendMaxMs': appendMicros.last / 1000,
        'reopenMs': reopen.elapsedMilliseconds,
        'authenticatedReplayMs': replay.elapsedMilliseconds,
        'replayEventsPerSecond':
            _eventCount * 1000 / replay.elapsedMilliseconds,
        'originUsageBytes': durability.usageBytes,
        'originQuotaBytes': durability.quotaBytes,
        'persistentStorage': durability.isPersistent,
      };
      // A single machine-readable line can be archived with a benchmark run.
      // ignore: avoid_print
      print('REBOOT_WEB_BENCHMARK ${jsonEncode(report)}');
    },
    timeout: const Timeout(Duration(minutes: 45)),
  );
}

WebPrototypePlainEvent _event(int sequence) => WebPrototypePlainEvent(
  eventId: '018f1f3a-7b1c-7a2d-8e3f-${sequence.toString().padLeft(12, '0')}',
  eventType: 'prototype.synthetic',
  schemaVersion: 1,
  payloadJson: _payload,
);

int _percentile(List<int> sortedValues, double fraction) {
  final index = ((sortedValues.length - 1) * fraction).round();
  return sortedValues[index];
}
