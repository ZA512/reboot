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
  /// The one local household profile and its cycle-policy history.
  household,

  /// One recurring income or outflow assumption.
  cashFlow,

  /// The household's annual reserve, project, and safety commitments.
  annualBudgetPlan,

  /// A real household expense transaction.
  expense,

  /// One named real or virtual household reserve.
  reserve,

  /// Optional aggregate household health tracking.
  healthTracking,

  /// Effective-dated cash withdrawal method and cash-wallet transfers.
  cashHandling,

  /// One already-received bonus amount assigned to ordinary daily life.
  receivedBonus,
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

/// Small optional behavioral qualification used by REBOOT statistics.
enum ExpenseNature {
  /// Essential spending that could not reasonably be avoided.
  necessary,

  /// Deliberate enjoyment or discretionary spending.
  pleasure,

  /// Spending that could have waited for a later cycle.
  deferrable,

  /// An unplanned expense outside the usual rhythm.
  unexpected,
}

/// Version 1 replacement fact for an expense's optional nature.
final class ExpenseNatureSetPayload implements EventPayload {
  /// Creates an explicit user-selected qualification.
  const ExpenseNatureSetPayload({required this.nature});

  @override
  String get eventType => 'expense.nature-set';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.expense;

  /// Latest user-selected behavioral nature.
  final ExpenseNature nature;
}

/// One virtual amount applied to a materialized weekly cycle.
final class ExpenseAllocation {
  /// Creates a non-negative EUR allocation.
  ExpenseAllocation({required this.cycleStart, required this.amount}) {
    if (amount.isNegative || amount.currency != Currency.eur) {
      throw ArgumentError.value(
        amount,
        'amount',
        'An expense allocation must be a non-negative EUR value.',
      );
    }
  }

  /// Start date identifying the target materialized cycle.
  final LocalDate cycleStart;

  /// Virtual amount reducing that cycle's remaining budget.
  final Money amount;

  @override
  bool operator ==(Object other) {
    return other is ExpenseAllocation &&
        cycleStart == other.cycleStart &&
        amount == other.amount;
  }

  @override
  int get hashCode => Object.hash(cycleStart, amount);
}

/// Version 1 payload fixing an expense's immutable 1-to-12-cycle plan.
final class ExpenseAllocationsPlannedPayload implements EventPayload {
  /// Creates and validates an already calculated allocation plan.
  ExpenseAllocationsPlannedPayload({
    required List<ExpenseAllocation> allocations,
  }) : allocations = List<ExpenseAllocation>.unmodifiable(allocations) {
    if (allocations.isEmpty || allocations.length > 12) {
      throw RangeError.range(allocations.length, 1, 12, 'allocations.length');
    }

    for (var index = 1; index < allocations.length; index++) {
      if (!allocations[index - 1].cycleStart.isBefore(
        allocations[index].cycleStart,
      )) {
        throw ArgumentError.value(
          allocations,
          'allocations',
          'Allocation cycle starts must be unique and strictly increasing.',
        );
      }
    }
    if (!total.isPositive) {
      throw ArgumentError.value(
        total,
        'allocations',
        'The complete allocation plan must have a positive total.',
      );
    }
  }

  /// Splits [expenseAmount] exactly across the ordered [cycleStarts].
  factory ExpenseAllocationsPlannedPayload.evenly({
    required Money expenseAmount,
    required List<LocalDate> cycleStarts,
  }) {
    if (!expenseAmount.isPositive || expenseAmount.currency != Currency.eur) {
      throw ArgumentError.value(
        expenseAmount,
        'expenseAmount',
        'An expense plan requires a positive EUR source amount.',
      );
    }
    if (cycleStarts.isEmpty || cycleStarts.length > 12) {
      throw RangeError.range(cycleStarts.length, 1, 12, 'cycleStarts.length');
    }

    final parts = expenseAmount.splitEvenly(cycleStarts.length);
    return ExpenseAllocationsPlannedPayload(
      allocations: [
        for (var index = 0; index < cycleStarts.length; index++)
          ExpenseAllocation(
            cycleStart: cycleStarts[index],
            amount: parts[index],
          ),
      ],
    );
  }

  @override
  String get eventType => 'expense.allocations.planned';

  @override
  int get schemaVersion => 1;

  @override
  EntityKind get targetKind => EntityKind.expense;

  /// Complete ordered allocation plan.
  final List<ExpenseAllocation> allocations;

  /// Exact total of all virtual allocations.
  Money get total {
    return allocations.fold(
      Money.zero(Currency.eur),
      (sum, allocation) => sum + allocation.amount,
    );
  }
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
  static final BigInt maxValue = BigInt.parse('9223372036854775807');

  /// Creates a validated signed 64-bit local position.
  factory LocalJournalPosition(int value) {
    return LocalJournalPosition.fromBigInt(BigInt.from(value));
  }

  /// Creates an exact position from a platform-independent integer.
  factory LocalJournalPosition.fromBigInt(BigInt value) {
    if (value < BigInt.one || value > maxValue) {
      throw RangeError('value must be inside the positive signed-64-bit range');
    }
    return LocalJournalPosition._(value);
  }

  LocalJournalPosition._(this.exactValue);

  /// Exact monotone local sequence number on every platform.
  final BigInt exactValue;

  /// Compatibility view for native SQLite and ordinary journal sizes.
  int get value {
    if (!exactValue.isValidInt) {
      throw StateError(
        'This journal position cannot be represented as a platform int.',
      );
    }
    return exactValue.toInt();
  }

  @override
  int compareTo(LocalJournalPosition other) =>
      exactValue.compareTo(other.exactValue);

  @override
  bool operator ==(Object other) {
    return other is LocalJournalPosition && exactValue == other.exactValue;
  }

  @override
  int get hashCode => exactValue.hashCode;

  @override
  String toString() => exactValue.toString();
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
