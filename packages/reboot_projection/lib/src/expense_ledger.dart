import 'package:reboot_domain/reboot_domain.dart';

import 'projection_errors.dart';

/// One immutable refund received for an expense and any later correction.
final class ProjectedExpenseRefund {
  const ProjectedExpenseRefund._({
    required this.eventId,
    required this.amount,
    required this.receivedDate,
    required this.receiptCycleStart,
    required this.recordedAtUtc,
    this.reversalEventId,
  });

  factory ProjectedExpenseRefund._fromEvent(EventRecord event) {
    final payload = event.payload as ExpenseRefundedPayload;
    return ProjectedExpenseRefund._(
      eventId: event.id,
      amount: payload.amount,
      receivedDate: event.businessDate,
      receiptCycleStart: payload.receiptCycleStart,
      recordedAtUtc: event.recordedAtUtc,
    );
  }

  /// Restores one validated derived refund from a projection checkpoint.
  factory ProjectedExpenseRefund.fromCheckpoint({
    required EventId eventId,
    required Money amount,
    required LocalDate receivedDate,
    required LocalDate receiptCycleStart,
    required DateTime recordedAtUtc,
    EventId? reversalEventId,
  }) {
    ExpenseRefundedPayload(
      amount: amount,
      receiptCycleStart: receiptCycleStart,
    );
    _requireUtc(recordedAtUtc, 'refund recordedAtUtc');
    if (eventId == reversalEventId) {
      throw const FormatException(
        'A refund cannot be reversed by its own event.',
      );
    }
    return ProjectedExpenseRefund._(
      eventId: eventId,
      amount: amount,
      receivedDate: receivedDate,
      receiptCycleStart: receiptCycleStart,
      recordedAtUtc: recordedAtUtc,
      reversalEventId: reversalEventId,
    );
  }

  final EventId eventId;
  final Money amount;
  final LocalDate receivedDate;
  final LocalDate receiptCycleStart;
  final DateTime recordedAtUtc;
  final EventId? reversalEventId;

  bool get isReversed => reversalEventId != null;

  ProjectedExpenseRefund _reversedBy(EventRecord event) =>
      ProjectedExpenseRefund._(
        eventId: eventId,
        amount: amount,
        receivedDate: receivedDate,
        receiptCycleStart: receiptCycleStart,
        recordedAtUtc: recordedAtUtc,
        reversalEventId: event.id,
      );

  @override
  bool operator ==(Object other) {
    return other is ProjectedExpenseRefund &&
        eventId == other.eventId &&
        amount == other.amount &&
        receivedDate == other.receivedDate &&
        receiptCycleStart == other.receiptCycleStart &&
        recordedAtUtc == other.recordedAtUtc &&
        reversalEventId == other.reversalEventId;
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    amount,
    receivedDate,
    receiptCycleStart,
    recordedAtUtc,
    reversalEventId,
  );
}

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
    required this.refunds,
    this.nature,
    this.natureEventId,
    this.allocations,
    this.allocationEventId,
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
      refunds: const [],
    );
  }

  /// Restores one validated derived expense from a projection checkpoint.
  ///
  /// Checkpoints are disposable caches. The immutable journal remains the
  /// source of truth if any invariant below is rejected.
  factory ProjectedExpense.fromCheckpoint({
    required EntityId id,
    required Money amount,
    required String label,
    required LocalDate purchaseDate,
    required ExpenseCycleAssignment cycleAssignment,
    required DateTime recordedAtUtc,
    required EventId recordingEventId,
    required List<ProjectedExpenseRefund> refunds,
    ExpenseNature? nature,
    EventId? natureEventId,
    List<ExpenseAllocation>? allocations,
    EventId? allocationEventId,
    DateTime? deletedAtUtc,
    EventId? deletionEventId,
  }) {
    ExpenseRecordedPayload(
      amount: amount,
      label: label,
      cycleAssignment: cycleAssignment,
    );
    _requireUtc(recordedAtUtc, 'expense recordedAtUtc');
    _requirePair(nature, natureEventId, 'expense nature');
    _requirePair(allocations, allocationEventId, 'expense allocations');
    _requirePair(deletedAtUtc, deletionEventId, 'expense deletion');
    if (deletedAtUtc != null) {
      _requireUtc(deletedAtUtc, 'expense deletedAtUtc');
      if (deletedAtUtc.isBefore(recordedAtUtc)) {
        throw const FormatException(
          'An expense cannot be deleted before it was recorded.',
        );
      }
    }

    final immutableAllocations = allocations == null
        ? null
        : List<ExpenseAllocation>.unmodifiable(allocations);
    if (immutableAllocations != null) {
      final payload = ExpenseAllocationsPlannedPayload(
        allocations: immutableAllocations,
      );
      if (payload.total != amount) {
        throw const FormatException(
          'Checkpoint allocations must total the expense amount.',
        );
      }
    }

    final immutableRefunds = List<ProjectedExpenseRefund>.unmodifiable(refunds);
    var refunded = Money.zero(Currency.eur);
    final refundIds = <EventId>{};
    for (final refund in immutableRefunds) {
      if (refund.recordedAtUtc.isBefore(recordedAtUtc)) {
        throw const FormatException(
          'A refund cannot precede its expense recording.',
        );
      }
      if (!refundIds.add(refund.eventId)) {
        throw FormatException('Duplicate refund event ${refund.eventId}.');
      }
      if (!refund.isReversed) refunded += refund.amount;
    }
    if (refunded.compareTo(amount) > 0) {
      throw const FormatException(
        'Active checkpoint refunds exceed the expense amount.',
      );
    }

    return ProjectedExpense._(
      id: id,
      amount: amount,
      label: label,
      purchaseDate: purchaseDate,
      cycleAssignment: cycleAssignment,
      recordedAtUtc: recordedAtUtc,
      recordingEventId: recordingEventId,
      refunds: immutableRefunds,
      nature: nature,
      natureEventId: natureEventId,
      allocations: immutableAllocations,
      allocationEventId: allocationEventId,
      deletedAtUtc: deletedAtUtc,
      deletionEventId: deletionEventId,
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

  /// Optional behavioral qualification; absence never invalidates an expense.
  final ExpenseNature? nature;

  /// Latest event that explicitly selected [nature].
  final EventId? natureEventId;

  /// Complete refund history, including corrected entries.
  final List<ProjectedExpenseRefund> refunds;

  /// Non-reversed refund entries.
  Iterable<ProjectedExpenseRefund> get activeRefunds =>
      refunds.where((refund) => !refund.isReversed);

  /// Total received and still active.
  Money get refundedAmount => activeRefunds.fold(
    Money.zero(Currency.eur),
    (sum, refund) => sum + refund.amount,
  );

  /// Amount still eligible for later refunds.
  Money get refundableAmount => amount - refundedAmount;

  /// Immutable virtual allocation plan, once its event is applied.
  final List<ExpenseAllocation>? allocations;

  /// Event that fixed [allocations], if any.
  final EventId? allocationEventId;

  /// Recording instant of the tombstone, if deleted.
  final DateTime? deletedAtUtc;

  /// Event that deleted the expense, if any.
  final EventId? deletionEventId;

  /// Whether a tombstone removed this expense from active totals.
  bool get isDeleted => deletionEventId != null;

  ProjectedExpense _allocatedBy(EventRecord event) {
    final payload = event.payload as ExpenseAllocationsPlannedPayload;
    if (allocations != null) {
      throw ProjectionConflictException(
        'Expense $id received multiple allocation plans.',
      );
    }
    if (isDeleted) {
      throw ProjectionConflictException(
        'Deleted expense $id cannot receive an allocation plan.',
      );
    }
    if (payload.total != amount) {
      throw ProjectionConflictException(
        'Expense $id allocations total ${payload.total} '
        'does not equal real amount $amount.',
      );
    }

    return ProjectedExpense._(
      id: id,
      amount: amount,
      label: label,
      purchaseDate: purchaseDate,
      cycleAssignment: cycleAssignment,
      recordedAtUtc: recordedAtUtc,
      recordingEventId: recordingEventId,
      refunds: refunds,
      nature: nature,
      natureEventId: natureEventId,
      allocations: payload.allocations,
      allocationEventId: event.id,
    );
  }

  ProjectedExpense _deletedBy(EventRecord event) {
    return ProjectedExpense._(
      id: id,
      amount: amount,
      label: label,
      purchaseDate: purchaseDate,
      cycleAssignment: cycleAssignment,
      recordedAtUtc: recordedAtUtc,
      recordingEventId: recordingEventId,
      nature: nature,
      natureEventId: natureEventId,
      allocations: allocations,
      allocationEventId: allocationEventId,
      deletedAtUtc: event.recordedAtUtc,
      deletionEventId: event.id,
      refunds: refunds,
    );
  }

  ProjectedExpense _refundedBy(EventRecord event) {
    if (isDeleted) {
      throw ProjectionConflictException(
        'Deleted expense $id cannot receive a refund.',
      );
    }
    final refund = ProjectedExpenseRefund._fromEvent(event);
    if (refundedAmount.exactMinorUnits + refund.amount.exactMinorUnits >
        amount.exactMinorUnits) {
      throw ProjectionConflictException(
        'Expense $id refunds exceed its original amount.',
      );
    }
    return ProjectedExpense._(
      id: id,
      amount: amount,
      label: label,
      purchaseDate: purchaseDate,
      cycleAssignment: cycleAssignment,
      recordedAtUtc: recordedAtUtc,
      recordingEventId: recordingEventId,
      nature: nature,
      natureEventId: natureEventId,
      allocations: allocations,
      allocationEventId: allocationEventId,
      deletedAtUtc: deletedAtUtc,
      deletionEventId: deletionEventId,
      refunds: [...refunds, refund],
    );
  }

  ProjectedExpense _reverseRefund(EventRecord event, EventId refundEventId) {
    final index = refunds.indexWhere(
      (refund) => refund.eventId == refundEventId,
    );
    if (index < 0) {
      throw ProjectionConflictException(
        'Expense $id does not contain refund $refundEventId.',
      );
    }
    if (refunds[index].isReversed) {
      throw ProjectionConflictException(
        'Refund $refundEventId received multiple reversals.',
      );
    }
    final next = List<ProjectedExpenseRefund>.of(refunds);
    next[index] = next[index]._reversedBy(event);
    return ProjectedExpense._(
      id: id,
      amount: amount,
      label: label,
      purchaseDate: purchaseDate,
      cycleAssignment: cycleAssignment,
      recordedAtUtc: recordedAtUtc,
      recordingEventId: recordingEventId,
      nature: nature,
      natureEventId: natureEventId,
      allocations: allocations,
      allocationEventId: allocationEventId,
      deletedAtUtc: deletedAtUtc,
      deletionEventId: deletionEventId,
      refunds: next,
    );
  }

  ProjectedExpense _natureSetBy(EventRecord event) {
    if (isDeleted) {
      throw ProjectionConflictException(
        'Deleted expense $id cannot receive a nature.',
      );
    }
    final payload = event.payload as ExpenseNatureSetPayload;
    return ProjectedExpense._(
      id: id,
      amount: amount,
      label: label,
      purchaseDate: purchaseDate,
      cycleAssignment: cycleAssignment,
      recordedAtUtc: recordedAtUtc,
      recordingEventId: recordingEventId,
      nature: payload.nature,
      natureEventId: event.id,
      allocations: allocations,
      allocationEventId: allocationEventId,
      deletedAtUtc: deletedAtUtc,
      deletionEventId: deletionEventId,
      refunds: refunds,
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
        nature == other.nature &&
        natureEventId == other.natureEventId &&
        _refundListsEqual(refunds, other.refunds) &&
        _allocationListsEqual(allocations, other.allocations) &&
        allocationEventId == other.allocationEventId &&
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
      nature,
      natureEventId,
      Object.hashAll(refunds),
      Object.hashAll(allocations ?? const <ExpenseAllocation>[]),
      allocationEventId,
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

  /// Restores a validated derived checkpoint at one exact journal position.
  ///
  /// Event UUID uniqueness is still enforced by the journal. Only event IDs
  /// retained by the current expense state are needed for local idempotence.
  factory ExpenseLedger.fromCheckpoint({
    required Iterable<ProjectedExpense> expenses,
    required LocalJournalPosition lastPosition,
  }) {
    final byId = <EntityId, ProjectedExpense>{};
    final appliedEventIds = <EventId>{};
    for (final expense in expenses) {
      if (byId.containsKey(expense.id)) {
        throw FormatException('Duplicate expense entity ${expense.id}.');
      }
      byId[expense.id] = expense;
      for (final eventId in _retainedEventIds(expense)) {
        if (!appliedEventIds.add(eventId)) {
          throw FormatException('Duplicate retained expense event $eventId.');
        }
      }
    }
    if (lastPosition.exactValue < BigInt.from(appliedEventIds.length)) {
      throw const FormatException(
        'The checkpoint position precedes its retained expense events.',
      );
    }
    return ExpenseLedger._(
      expenses: byId,
      appliedEventIds: appliedEventIds,
      lastPosition: lastPosition,
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
    if (entry.event.target.kind == EntityKind.expense) {
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
        case ExpenseAllocationsPlannedPayload():
          final existing = nextExpenses[entry.event.target.id];
          if (existing == null) {
            throw ProjectionConflictException(
              'Expense ${entry.event.target.id} was allocated before recording.',
            );
          }
          nextExpenses[entry.event.target.id] = existing._allocatedBy(
            entry.event,
          );
        case ExpenseNatureSetPayload():
          final existing = nextExpenses[entry.event.target.id];
          if (existing == null) {
            throw ProjectionConflictException(
              'Expense ${entry.event.target.id} was qualified before recording.',
            );
          }
          nextExpenses[entry.event.target.id] = existing._natureSetBy(
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
          nextExpenses[entry.event.target.id] = existing._deletedBy(
            entry.event,
          );
        case ExpenseRefundedPayload():
          final existing = nextExpenses[entry.event.target.id];
          if (existing == null) {
            throw ProjectionConflictException(
              'Expense ${entry.event.target.id} was refunded before recording.',
            );
          }
          nextExpenses[entry.event.target.id] = existing._refundedBy(
            entry.event,
          );
        case ExpenseRefundReversedPayload(:final refundEventId):
          final existing = nextExpenses[entry.event.target.id];
          if (existing == null) {
            throw ProjectionConflictException(
              'Expense ${entry.event.target.id} had a refund reversed before recording.',
            );
          }
          nextExpenses[entry.event.target.id] = existing._reverseRefund(
            entry.event,
            refundEventId,
          );
        default:
          throw UnsupportedEventException(entry.event.eventType);
      }
    }

    return ExpenseLedger._(
      expenses: nextExpenses,
      appliedEventIds: {..._appliedEventIds, entry.event.id},
      lastPosition: entry.position,
    );
  }
}

Iterable<EventId> _retainedEventIds(ProjectedExpense expense) sync* {
  yield expense.recordingEventId;
  if (expense.natureEventId case final eventId?) yield eventId;
  if (expense.allocationEventId case final eventId?) yield eventId;
  if (expense.deletionEventId case final eventId?) yield eventId;
  for (final refund in expense.refunds) {
    yield refund.eventId;
    if (refund.reversalEventId case final eventId?) yield eventId;
  }
}

void _requireUtc(DateTime value, String field) {
  if (!value.isUtc) {
    throw FormatException('$field must be expressed in UTC.');
  }
}

void _requirePair(Object? value, Object? eventId, String field) {
  if ((value == null) != (eventId == null)) {
    throw FormatException('$field value and event ID must appear together.');
  }
}

bool _refundListsEqual(
  List<ProjectedExpenseRefund> left,
  List<ProjectedExpenseRefund> right,
) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.eventId != b.eventId ||
        a.amount != b.amount ||
        a.receivedDate != b.receivedDate ||
        a.receiptCycleStart != b.receiptCycleStart ||
        a.recordedAtUtc != b.recordedAtUtc ||
        a.reversalEventId != b.reversalEventId) {
      return false;
    }
  }
  return true;
}

bool _allocationListsEqual(
  List<ExpenseAllocation>? left,
  List<ExpenseAllocation>? right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null || left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
