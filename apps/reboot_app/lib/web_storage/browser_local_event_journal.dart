import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_serialization/reboot_serialization.dart';

import 'browser_encrypted_journal_prototype.dart';
import 'encrypted_event_envelope.dart';

/// Browser implementation of the application's append-only event journal.
///
/// This adapter is intentionally not selected by the application shell until
/// Web recovery and projection snapshots are ready for production use.
final class BrowserLocalEventJournal implements LocalEventJournal {
  BrowserLocalEventJournal._(this._journal, this._codec);

  /// Opens the encrypted IndexedDB journal identified by [databaseName].
  static Future<BrowserLocalEventJournal> open({
    required String databaseName,
  }) async {
    return BrowserLocalEventJournal._(
      await BrowserEncryptedJournalPrototype.open(databaseName: databaseName),
      EventRecordJsonCodec(),
    );
  }

  final BrowserEncryptedJournalPrototype _journal;
  final EventRecordJsonCodec _codec;

  @override
  Future<List<LocalJournalEntry>> readAll() async {
    final events = await _journal.readAll();
    return List<LocalJournalEntry>.unmodifiable(<LocalJournalEntry>[
      for (var index = 0; index < events.length; index += 1)
        LocalJournalEntry(
          position: LocalJournalPosition.fromBigInt(BigInt.from(index + 1)),
          event: _decode(events[index]),
        ),
    ]);
  }

  @override
  Future<List<LocalJournalEntry>> appendAll(List<EventRecord> events) async {
    try {
      final positions = await _journal.appendAll(
        events.map(_encode).toList(growable: false),
      );
      return List<LocalJournalEntry>.unmodifiable(<LocalJournalEntry>[
        for (var index = 0; index < events.length; index += 1)
          LocalJournalEntry(
            position: LocalJournalPosition.fromBigInt(positions[index]),
            event: events[index],
          ),
      ]);
    } on WebJournalEventConflictException catch (error) {
      throw JournalEventConflictException(EventId(error.eventId));
    }
  }

  @override
  Future<void> close() async => _journal.close();

  WebPrototypePlainEvent _encode(EventRecord event) {
    return WebPrototypePlainEvent(
      eventId: event.id.value,
      eventType: event.eventType,
      schemaVersion: event.schemaVersion,
      payloadJson: _codec.encode(event),
    );
  }

  EventRecord _decode(WebPrototypePlainEvent stored) {
    try {
      final event = _codec.decode(stored.payloadJson);
      if (event.id.value != stored.eventId ||
          event.eventType != stored.eventType ||
          event.schemaVersion != stored.schemaVersion) {
        throw const WebJournalIntegrityException();
      }
      return event;
    } on WebJournalIntegrityException {
      rethrow;
    } on Object {
      throw const WebJournalIntegrityException();
    }
  }
}
