import 'cycles.dart';
import 'local_date.dart';
import 'money.dart';

final RegExp _canonicalUuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-'
  r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Stable UUID identity of an immutable domain event.
final class EventId {
  /// Parses a canonical lowercase UUID.
  factory EventId(String value) {
    _requireCanonicalUuid(value, 'event ID');
    return EventId._(value);
  }

  const EventId._(this.value);

  /// Canonical UUID text.
  final String value;

  @override
  bool operator ==(Object other) => other is EventId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Stable UUID identity of a domain entity.
final class EntityId {
  /// Parses a canonical lowercase UUID.
  factory EntityId(String value) {
    _requireCanonicalUuid(value, 'entity ID');
    return EntityId._(value);
  }

  const EntityId._(this.value);

  /// Canonical UUID text.
  final String value;

  @override
  bool operator ==(Object other) => other is EntityId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

void _requireCanonicalUuid(String value, String label) {
  if (!_canonicalUuidPattern.hasMatch(value)) {
    throw FormatException('Invalid canonical UUID $label: $value');
  }
}

/// Domain entity categories that may be targeted by events.
enum EntityKind {
  /// A real household expense transaction.
  expense,
}

/// Typed target of an immutable event.
final class EntityReference {
  /// Creates a reference to an entity of [kind].
  const EntityReference({required this.kind, required this.id});

  /// Entity category.
  final EntityKind kind;

  /// Stable entity UUID.
  final EntityId id;

  @override
  bool operator ==(Object other) {
    return other is EntityReference && kind == other.kind && id == other.id;
  }

  @override
  int get hashCode => Object.hash(kind, id);
}

/// Immutable typed content stored inside an [EventRecord].
abstract interface class EventPayload {
  /// Stable event type used by persistence and migrations.
  String get eventType;

  /// Positive schema version of this payload.
  int get schemaVersion;

  /// Entity category accepted as the event target.
  EntityKind get targetKind;
}

/// Historical cycle assignment captured when an expense is recorded.
final class ExpenseCycleAssignment {
  /// Creates an auditable cycle assignment.
  ExpenseCycleAssignment({
    required this.cycleStart,
    required this.policyVersion,
    required this.timeZone,
  }) {
    if (policyVersion < 1) {
      throw RangeError.range(policyVersion, 1, null, 'policyVersion');
    }
  }

  /// Materialized cycle start; it never shifts after a policy change.
  final LocalDate cycleStart;

  /// Cycle-policy version used for the assignment.
  final int policyVersion;

  /// Household time zone used to derive the purchase date.
  final IanaTimeZoneId timeZone;

  @override
  bool operator ==(Object other) {
    return other is ExpenseCycleAssignment &&
        cycleStart == other.cycleStart &&
        policyVersion == other.policyVersion &&
        timeZone == other.timeZone;
  }

  @override
  int get hashCode => Object.hash(cycleStart, policyVersion, timeZone);
}

/// Version 1 payload for recording one real expense.
final class ExpenseRecordedPayload implements EventPayload {
  /// Creates a validated EUR expense payload.
  ExpenseRecordedPayload({
    required this.amount,
    required this.label,
    required this.cycleAssignment,
  }) {
    if (!amount.isPositive) {
      throw ArgumentError.value(
        amount,
        'amount',
        'An expense amount must be strictly positive.',
      );
    }
    if (amount.currency != Currency.eur) {
      throw ArgumentError.value(
        amount.currency,
        'amount',
        'The first REBOOT household event schema supports EUR only.',
      );
    }
    if (label.trim().isEmpty) {
      throw ArgumentError.value(
        label,
        'label',
        'An expense label is required.',
      );
    }
  }

  @override
  String get eventType => 'expense.recorded';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.expense;

  /// Exact real transaction amount.
  final Money amount;

  /// User-visible description entered with the expense.
  final String label;

  /// Cycle assignment frozen at creation time.
  final ExpenseCycleAssignment cycleAssignment;
}

/// Version 1 tombstone payload for deleting an erroneous expense.
final class ExpenseDeletedPayload implements EventPayload {
  /// Creates an expense tombstone payload.
  const ExpenseDeletedPayload();

  @override
  String get eventType => 'expense.deleted';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.expense;
}

/// Immutable business event before local journal or sync metadata is attached.
final class EventRecord {
  /// Creates and validates an immutable event.
  EventRecord({
    required this.id,
    required this.recordedAtUtc,
    required this.businessDate,
    required this.target,
    required this.payload,
  }) {
    if (!recordedAtUtc.isUtc) {
      throw ArgumentError.value(
        recordedAtUtc,
        'recordedAtUtc',
        'The recording instant must be expressed in UTC.',
      );
    }
    if (payload.schemaVersion < 1) {
      throw ArgumentError.value(
        payload.schemaVersion,
        'payload',
        'An event schema version must be positive.',
      );
    }
    if (target.kind != payload.targetKind) {
      throw ArgumentError(
        'Event ${payload.eventType} cannot target ${target.kind.name}.',
      );
    }
  }

  /// Stable UUID preserved if synchronization is activated later.
  final EventId id;

  /// UTC instant at which the event entered the local journal.
  final DateTime recordedAtUtc;

  /// Civil date on which the business fact occurred.
  final LocalDate businessDate;

  /// Entity affected by the business fact.
  final EntityReference target;

  /// Versioned immutable business content.
  final EventPayload payload;

  /// Stable event type delegated by [payload].
  String get eventType => payload.eventType;

  /// Payload schema version delegated by [payload].
  int get schemaVersion => payload.schemaVersion;
}

/// Positive, monotone position assigned only by one local journal.
final class LocalJournalPosition implements Comparable<LocalJournalPosition> {
  /// Largest value supported by the persisted signed 64-bit representation.
  static const int maxValue = 9223372036854775807;

  /// Creates a validated signed 64-bit local position.
  factory LocalJournalPosition(int value) {
    if (value < 1 || value > maxValue) {
      throw RangeError.range(value, 1, maxValue, 'value');
    }
    return LocalJournalPosition._(value);
  }

  const LocalJournalPosition._(this.value);

  /// Monotone local sequence number.
  final int value;

  @override
  int compareTo(LocalJournalPosition other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) {
    return other is LocalJournalPosition && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value.toString();
}

/// One local journal row, distinct from future synchronization metadata.
final class LocalJournalEntry {
  /// Attaches a local replay position to [event].
  const LocalJournalEntry({required this.position, required this.event});

  /// Position used only for deterministic replay on this device.
  final LocalJournalPosition position;

  /// Immutable business event.
  final EventRecord event;
}
