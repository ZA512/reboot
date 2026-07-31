import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseLedger replay', () {
    test('reconstructs one active expense from its event', () {
      final ledger = ExpenseLedger.replay([_recordedEntry()]);

      expect(ledger.expenses, hasLength(1));
      expect(ledger.activeExpenses, hasLength(1));
      final expense = ledger.activeExpenses.single;
      expect(expense.id, _expenseId);
      expect(expense.amount, Money.fromMinorUnits(4250, Currency.eur));
      expect(expense.label, 'Courses');
      expect(expense.purchaseDate, LocalDate(2026, 4, 1));
      expect(expense.cycleAssignment.cycleStart, LocalDate(2026, 3, 28));
      expect(expense.isDeleted, isFalse);
    });

    test('applies a tombstone without erasing the auditable expense', () {
      final ledger = ExpenseLedger.replay([_recordedEntry(), _deletedEntry()]);

      expect(ledger.activeExpenses, isEmpty);
      expect(ledger.expenses, hasLength(1));
      final tombstone = ledger.expenses[_expenseId]!;
      expect(tombstone.isDeleted, isTrue);
      expect(tombstone.deletionEventId, _deletionEventId);
      expect(tombstone.amount, Money.fromMinorUnits(4250, Currency.eur));
    });

    test('attaches one exact immutable allocation plan', () {
      final ledger = ExpenseLedger.replay([
        _recordedEntry(),
        _allocationEntry(),
      ]);

      final expense = ledger.activeExpenses.single;
      expect(expense.allocations, hasLength(3));
      expect(
        expense.allocations!.map((allocation) => allocation.amount.minorUnits),
        [1416, 1416, 1418],
      );
      expect(expense.allocationEventId, _allocationEventId);
    });

    test('reapplying an event UUID is strictly idempotent', () {
      final first = ExpenseLedger.empty().apply(_recordedEntry());
      final repeated = first.apply(_recordedEntry());

      expect(identical(repeated, first), isTrue);
      expect(repeated.activeExpenses, hasLength(1));
    });

    test('full replay matches incremental projection', () {
      final entries = [_recordedEntry(), _deletedEntry()];
      final fullReplay = ExpenseLedger.replay(entries);
      final incremental = ExpenseLedger.empty()
          .apply(entries.first)
          .apply(entries.last);

      expect(incremental.expenses, fullReplay.expenses);
      expect(incremental.lastPosition, fullReplay.lastPosition);
      expect(incremental.activeExpenses, fullReplay.activeExpenses);
    });

    test('keeps observable projection collections immutable', () {
      final ledger = ExpenseLedger.replay([_recordedEntry()]);

      expect(() => ledger.expenses.clear(), throwsUnsupportedError);
    });
  });

  group('ExpenseLedger invariant failures', () {
    test('rejects decreasing local positions for distinct events', () {
      final ledger = ExpenseLedger.empty().apply(_recordedEntry());
      final invalidDeletion = LocalJournalEntry(
        position: LocalJournalPosition(1),
        event: _deletedEvent(),
      );

      expect(
        () => ledger.apply(invalidDeletion),
        throwsA(isA<LocalJournalOrderException>()),
      );
    });

    test('rejects a tombstone before the expense exists', () {
      expect(
        () => ExpenseLedger.empty().apply(_deletedEntry()),
        throwsA(isA<ProjectionConflictException>()),
      );
    });

    test('rejects allocation before recording or with a wrong total', () {
      expect(
        () => ExpenseLedger.empty().apply(_allocationEntry()),
        throwsA(isA<ProjectionConflictException>()),
      );

      final wrongAllocation = LocalJournalEntry(
        position: LocalJournalPosition(2),
        event: EventRecord(
          id: _allocationEventId,
          recordedAtUtc: DateTime.utc(2026, 4, 1, 10, 0, 1),
          businessDate: LocalDate(2026, 4, 1),
          target: _expenseReference,
          payload: ExpenseAllocationsPlannedPayload(
            allocations: [
              ExpenseAllocation(
                cycleStart: LocalDate(2026, 3, 28),
                amount: Money.fromMinorUnits(4000, Currency.eur),
              ),
            ],
          ),
        ),
      );
      final recorded = ExpenseLedger.empty().apply(_recordedEntry());

      expect(
        () => recorded.apply(wrongAllocation),
        throwsA(isA<ProjectionConflictException>()),
      );
    });

    test('rejects two recording facts for one expense identity', () {
      final secondRecording = LocalJournalEntry(
        position: LocalJournalPosition(2),
        event: EventRecord(
          id: EventId('01902222-2222-7222-8222-222222222222'),
          recordedAtUtc: DateTime.utc(2026, 4, 1, 12),
          businessDate: LocalDate(2026, 4, 1),
          target: _expenseReference,
          payload: _recordedPayload(),
        ),
      );
      final ledger = ExpenseLedger.empty().apply(_recordedEntry());

      expect(
        () => ledger.apply(secondRecording),
        throwsA(isA<ProjectionConflictException>()),
      );
    });
  });
}

final EntityId _expenseId = EntityId('01901111-1111-7111-8111-111111111111');
final EventId _recordingEventId = EventId(
  '018f1f3a-7b1c-7a2d-8e3f-1234567890ab',
);
final EventId _deletionEventId = EventId(
  '01903333-3333-7333-8333-333333333333',
);
final EventId _allocationEventId = EventId(
  '01904444-4444-7444-8444-444444444444',
);
final EntityReference _expenseReference = EntityReference(
  kind: EntityKind.expense,
  id: _expenseId,
);

LocalJournalEntry _recordedEntry() {
  return LocalJournalEntry(
    position: LocalJournalPosition(1),
    event: EventRecord(
      id: _recordingEventId,
      recordedAtUtc: DateTime.utc(2026, 4, 1, 10),
      businessDate: LocalDate(2026, 4, 1),
      target: _expenseReference,
      payload: _recordedPayload(),
    ),
  );
}

LocalJournalEntry _deletedEntry() {
  return LocalJournalEntry(
    position: LocalJournalPosition(2),
    event: _deletedEvent(),
  );
}

LocalJournalEntry _allocationEntry() {
  return LocalJournalEntry(
    position: LocalJournalPosition(2),
    event: EventRecord(
      id: _allocationEventId,
      recordedAtUtc: DateTime.utc(2026, 4, 1, 10, 0, 1),
      businessDate: LocalDate(2026, 4, 1),
      target: _expenseReference,
      payload: ExpenseAllocationsPlannedPayload.evenly(
        expenseAmount: Money.fromMinorUnits(4250, Currency.eur),
        cycleStarts: [
          LocalDate(2026, 3, 28),
          LocalDate(2026, 4, 4),
          LocalDate(2026, 4, 11),
        ],
      ),
    ),
  );
}

EventRecord _deletedEvent() {
  return EventRecord(
    id: _deletionEventId,
    recordedAtUtc: DateTime.utc(2026, 4, 2, 8),
    businessDate: LocalDate(2026, 4, 2),
    target: _expenseReference,
    payload: const ExpenseDeletedPayload(),
  );
}

ExpenseRecordedPayload _recordedPayload() {
  return ExpenseRecordedPayload(
    amount: Money.fromMinorUnits(4250, Currency.eur),
    label: 'Courses',
    cycleAssignment: ExpenseCycleAssignment(
      cycleStart: LocalDate(2026, 3, 28),
      policyVersion: 1,
      timeZone: IanaTimeZoneId('Europe/Paris'),
    ),
  );
}
