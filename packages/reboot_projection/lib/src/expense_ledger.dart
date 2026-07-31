import 'package:reboot_domain/reboot_domain.dart';

/// Observable expense reconstructed solely from immutable journal events.
final class ProjectedExpense {
  const ProjectedExpense._({
    required this.id,
    required this.amount,
    required this.label,
    required this.purchaseDate,
    required this.cycleAssignment,
    required this.recordedAtUtc,
    required this.recordingEventId,
    this.deletedAtUtc,
    this.deletionEventId,
  });

  factory ProjectedExpense._recorded(EventRecord event) {
    final payload = event.payload as ExpenseRecordedPayload;
    return ProjectedExpense._(
      id: event.target.id,
      amount: payload.amount,
      label: payload.label,
      purchaseDate: event.businessDate,
      cycleAssignment: payload.cycleAssignment,
      recordedAtUtc: event.recordedAtUtc,
      recordingEventId: event.id,
    );
  }

  /// Stable expense entity identity.
  final EntityId id;

  /// Exact real transaction amount.
  final Money amount;

  /// User-visible description.
  final String label;

  /// Purchase date in the household time zone at creation.
  final LocalDate purchaseDate;

  /// Historical cycle assignment that must not shift.
  final ExpenseCycleAssignment cycleAssignment;

  /// Recording instant of the original expense event.
  final DateTime recordedAtUtc;

  /// Event that created this projection.
  final EventId recordingEventId;

  /// Recording instant of the tombstone, if deleted.
  final DateTime? deletedAtUtc;

  /// Event that deleted the expense, if any.
  final EventId? deletionEventId;

  /// Whether a tombstone removed this expense from active totals.
  bool get isDeleted => deletionEventId != null;

  ProjectedExpense _deletedBy(EventRecord event) {
    return ProjectedExpense._(
      id: id,
      amount: amount,
      label: label,
      purchaseDate: purchaseDate,
      cycleAssignment: cycleAssignment,
      recordedAtUtc: recordedAtUtc,
      recordingEventId: recordingEventId,
      deletedAtUtc: event.recordedAtUtc,
      deletionEventId: event.id,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectedExpense &&
        id == other.id &&
        amount == other.amount &&
        label == other.label &&
        purchaseDate == other.purchaseDate &&
        cycleAssignment == other.cycleAssignment &&
        recordedAtUtc == other.recordedAtUtc &&
        recordingEventId == other.recordingEventId &&
        deletedAtUtc == other.deletedAtUtc &&
        deletionEventId == other.deletionEventId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      amount,
      label,
      purchaseDate,
      cycleAssignment,
      recordedAtUtc,
      recordingEventId,
      deletedAtUtc,
      deletionEventId,
    );
  }
}

/// Immutable projection of all expense records and tombstones.
final class ExpenseLedger {
  ExpenseLedger._({
    required Map<EntityId, ProjectedExpense> expenses,
    required Set<EventId> appliedEventIds,
    required this.lastPosition,
  }) : expenses = Map<EntityId, ProjectedExpense>.unmodifiable(expenses),
       _appliedEventIds = Set<EventId>.unmodifiable(appliedEventIds);

  /// Creates an empty projection.
  factory ExpenseLedger.empty() {
    return ExpenseLedger._(
      expenses: const {},
      appliedEventIds: const {},
      lastPosition: null,
    );
  }

  /// Replays a complete ordered local journal.
  factory ExpenseLedger.replay(Iterable<LocalJournalEntry> entries) {
    return entries.fold(
      ExpenseLedger.empty(),
      (ledger, entry) => ledger.apply(entry),
    );
  }

  /// All known expenses, including deleted tombstones.
  final Map<EntityId, ProjectedExpense> expenses;

  final Set<EventId> _appliedEventIds;

  /// Last non-duplicate local position applied, if any.
  final LocalJournalPosition? lastPosition;

  /// Active expenses that contribute to observable totals.
  Iterable<ProjectedExpense> get activeExpenses {
    return expenses.values.where((expense) => !expense.isDeleted);
  }

  /// Applies one ordered journal entry and returns a new projection.
  ///
  /// Reapplying an already-seen event UUID returns this exact instance.
  ExpenseLedger apply(LocalJournalEntry entry) {
    if (_appliedEventIds.contains(entry.event.id)) {
      return this;
    }
    if (lastPosition != null && entry.position.compareTo(lastPosition!) <= 0) {
      throw LocalJournalOrderException(
        previous: lastPosition!,
        received: entry.position,
      );
    }

    final nextExpenses = Map<EntityId, ProjectedExpense>.of(expenses);
    switch (entry.event.payload) {
      case ExpenseRecordedPayload():
        if (nextExpenses.containsKey(entry.event.target.id)) {
          throw ProjectionConflictException(
            'Expense ${entry.event.target.id} was recorded more than once.',
          );
        }
        nextExpenses[entry.event.target.id] = ProjectedExpense._recorded(
          entry.event,
        );
      case ExpenseDeletedPayload():
        final existing = nextExpenses[entry.event.target.id];
        if (existing == null) {
          throw ProjectionConflictException(
            'Expense ${entry.event.target.id} was deleted before recording.',
          );
        }
        if (existing.isDeleted) {
          throw ProjectionConflictException(
            'Expense ${entry.event.target.id} received multiple tombstones.',
          );
        }
        nextExpenses[entry.event.target.id] = existing._deletedBy(entry.event);
      default:
        throw UnsupportedEventException(entry.event.eventType);
    }

    return ExpenseLedger._(
      expenses: nextExpenses,
      appliedEventIds: {..._appliedEventIds, entry.event.id},
      lastPosition: entry.position,
    );
  }
}

/// Indicates that local journal entries were not replayed monotonically.
final class LocalJournalOrderException implements Exception {
  /// Creates an ordering error.
  const LocalJournalOrderException({
    required this.previous,
    required this.received,
  });

  /// Last accepted position.
  final LocalJournalPosition previous;

  /// Non-increasing position that was rejected.
  final LocalJournalPosition received;

  @override
  String toString() {
    return 'LocalJournalOrderException: position $received follows $previous';
  }
}

/// Indicates contradictory immutable facts in one journal.
final class ProjectionConflictException implements Exception {
  /// Creates a conflict with a diagnostic [message].
  const ProjectionConflictException(this.message);

  /// Human-readable diagnostic for developers.
  final String message;

  @override
  String toString() => 'ProjectionConflictException: $message';
}

/// Indicates that this projection does not understand an event schema.
final class UnsupportedEventException implements Exception {
  /// Creates an unsupported-event error for [eventType].
  const UnsupportedEventException(this.eventType);

  /// Stable event type rejected by the projection.
  final String eventType;

  @override
  String toString() => 'UnsupportedEventException: $eventType';
}
