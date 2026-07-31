import 'package:drift/drift.dart';
import 'package:reboot_application/reboot_application.dart';
import 'package:reboot_domain/reboot_domain.dart';

import 'database.dart';
import 'event_codec.dart';

/// Drift-backed implementation of the one encrypted local event journal.
final class RebootEventJournal implements LocalEventJournal {
  RebootEventJournal._(this._database, this._codec);

  /// Opens an encrypted journal file and forces schema validation.
  static Future<RebootEventJournal> open({
    required String filePath,
    required EncryptedDatabaseKey key,
  }) async {
    final database = await RebootDatabase.open(filePath: filePath, key: key);
    return RebootEventJournal._(database, EventPayloadJsonCodec());
  }

  final RebootDatabase _database;
  final EventPayloadJsonCodec _codec;

  /// Appends one event and returns its assigned local position.
  Future<LocalJournalEntry> append(EventRecord event) async {
    return (await appendAll([event])).single;
  }

  @override
  Future<List<LocalJournalEntry>> readAll() async {
    final rows = await (_database.select(
      _database.localEvents,
    )..orderBy([(table) => OrderingTerm.asc(table.localPosition)])).get();
    return List<LocalJournalEntry>.unmodifiable(rows.map(_decodeRow));
  }

  @override
  Future<List<LocalJournalEntry>> appendAll(List<EventRecord> events) async {
    if (events.isEmpty) {
      return const [];
    }
    return _database.transaction(() async {
      final appended = <LocalJournalEntry>[];
      for (final event in events) {
        final payloadJson = _codec.encode(event.payload);
        final existing =
            await (_database.select(_database.localEvents)
                  ..where((table) => table.eventId.equals(event.id.value)))
                .getSingleOrNull();
        if (existing != null) {
          if (!_matches(existing, event, payloadJson)) {
            throw JournalEventConflictException(event.id);
          }
          appended.add(_decodeRow(existing));
          continue;
        }

        final position = await _database
            .into(_database.localEvents)
            .insert(
              LocalEventsCompanion.insert(
                eventId: event.id.value,
                recordedAtUtcMicros: event.recordedAtUtc.microsecondsSinceEpoch,
                businessDate: event.businessDate.toString(),
                entityKind: event.target.kind.name,
                entityId: event.target.id.value,
                eventType: event.eventType,
                eventSchemaVersion: event.schemaVersion,
                payloadJson: payloadJson,
              ),
            );
        appended.add(
          LocalJournalEntry(
            position: LocalJournalPosition(position),
            event: event,
          ),
        );
      }
      return List<LocalJournalEntry>.unmodifiable(appended);
    });
  }

  @override
  Future<void> close() => _database.close();

  bool _matches(LocalEvent row, EventRecord event, String payloadJson) {
    return row.eventId == event.id.value &&
        row.recordedAtUtcMicros == event.recordedAtUtc.microsecondsSinceEpoch &&
        row.businessDate == event.businessDate.toString() &&
        row.entityKind == event.target.kind.name &&
        row.entityId == event.target.id.value &&
        row.eventType == event.eventType &&
        row.eventSchemaVersion == event.schemaVersion &&
        row.payloadJson == payloadJson;
  }

  LocalJournalEntry _decodeRow(LocalEvent row) {
    final kind = _entityKind(row.entityKind);
    final payload = _codec.decode(
      eventType: row.eventType,
      schemaVersion: row.eventSchemaVersion,
      json: row.payloadJson,
    );
    return LocalJournalEntry(
      position: LocalJournalPosition(row.localPosition),
      event: EventRecord(
        id: EventId(row.eventId),
        recordedAtUtc: DateTime.fromMicrosecondsSinceEpoch(
          row.recordedAtUtcMicros,
          isUtc: true,
        ),
        businessDate: _date(row.businessDate),
        target: EntityReference(kind: kind, id: EntityId(row.entityId)),
        payload: payload,
      ),
    );
  }
}

/// Reuse of an event UUID with different immutable content.
final class JournalEventConflictException implements Exception {
  /// Creates a UUID collision error that contains no financial data.
  const JournalEventConflictException(this.eventId);

  /// Colliding event identity.
  final EventId eventId;

  @override
  String toString() => 'JournalEventConflictException: $eventId';
}

EntityKind _entityKind(String name) {
  for (final kind in EntityKind.values) {
    if (kind.name == name) {
      return kind;
    }
  }
  throw FormatException('Unsupported stored entity kind: $name');
}

LocalDate _date(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw const FormatException('Invalid stored business date.');
  }
  return LocalDate(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}
