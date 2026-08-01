import 'package:reboot_domain/reboot_domain.dart';

/// Append-only persistence boundary for the one local event journal.
abstract interface class LocalEventJournal {
  /// Reads every event in strict local-position order.
  Future<List<LocalJournalEntry>> readAll();

  /// Atomically appends [events] and returns their assigned local positions.
  ///
  /// Reapplying an identical event UUID is idempotent. Reusing a UUID with
  /// different immutable content must fail without partially appending a batch.
  Future<List<LocalJournalEntry>> appendAll(List<EventRecord> events);

  /// Releases all local storage resources.
  Future<void> close();
}

/// Convenience operations shared by every journal implementation.
extension LocalEventJournalOperations on LocalEventJournal {
  /// Appends one event and returns its local journal entry.
  Future<LocalJournalEntry> append(EventRecord event) async {
    return (await appendAll([event])).single;
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
