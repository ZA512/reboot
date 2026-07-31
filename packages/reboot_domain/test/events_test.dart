import 'package:reboot_domain/reboot_domain.dart';
import 'package:test/test.dart';

void main() {
  group('event and entity identities', () {
    test('accept canonical UUIDs and preserve distinct types', () {
      final eventId = EventId('018f1f3a-7b1c-7a2d-8e3f-1234567890ab');
      final entityId = EntityId('018f1f3a-7b1c-7a2d-8e3f-1234567890ab');

      expect(eventId.value, entityId.value);
      expect(eventId, isNot(equals(entityId)));
    });

    test('rejects malformed, uppercase, nil, and non-versioned UUIDs', () {
      expect(() => EventId('not-a-uuid'), throwsFormatException);
      expect(
        () => EventId('018F1F3A-7B1C-7A2D-8E3F-1234567890AB'),
        throwsFormatException,
      );
      expect(
        () => EventId('00000000-0000-0000-0000-000000000000'),
        throwsFormatException,
      );
    });
  });

  group('ExpenseRecordedPayload', () {
    test('captures exact EUR value and historical cycle assignment', () {
      final payload = _recordedPayload();

      expect(payload.eventType, 'expense.recorded');
      expect(payload.schemaVersion, 1);
      expect(payload.targetKind, EntityKind.expense);
      expect(payload.amount, Money.fromMinorUnits(4250, Currency.eur));
      expect(payload.cycleAssignment.cycleStart, LocalDate(2026, 3, 28));
      expect(payload.cycleAssignment.policyVersion, 1);
      expect(payload.cycleAssignment.timeZone.value, 'Europe/Paris');
    });

    test('rejects zero, negative, non-EUR, or unlabeled expenses', () {
      expect(
        () => ExpenseRecordedPayload(
          amount: Money.zero(Currency.eur),
          label: 'Courses',
          cycleAssignment: _assignment(),
        ),
        throwsArgumentError,
      );
      expect(
        () => ExpenseRecordedPayload(
          amount: Money.fromMinorUnits(-1, Currency.eur),
          label: 'Courses',
          cycleAssignment: _assignment(),
        ),
        throwsArgumentError,
      );
      expect(
        () => ExpenseRecordedPayload(
          amount: Money.fromMinorUnits(100, Currency.usd),
          label: 'Groceries',
          cycleAssignment: _assignment(),
        ),
        throwsArgumentError,
      );
      expect(
        () => ExpenseRecordedPayload(
          amount: Money.fromMinorUnits(100, Currency.eur),
          label: '   ',
          cycleAssignment: _assignment(),
        ),
        throwsArgumentError,
      );
    });
  });

  test('ExpenseNatureSetPayload remains optional and targets one expense', () {
    const payload = ExpenseNatureSetPayload(nature: ExpenseNature.deferrable);

    expect(payload.eventType, 'expense.nature-set');
    expect(payload.targetKind, EntityKind.expense);
    expect(payload.nature, ExpenseNature.deferrable);
  });

  group('ExpenseAllocationsPlannedPayload', () {
    test('splits 28 EUR exactly across three ordered cycles', () {
      final payload = ExpenseAllocationsPlannedPayload.evenly(
        expenseAmount: Money.fromMinorUnits(2800, Currency.eur),
        cycleStarts: [
          LocalDate(2026, 3, 28),
          LocalDate(2026, 4, 4),
          LocalDate(2026, 4, 11),
        ],
      );

      expect(payload.eventType, 'expense.allocations.planned');
      expect(payload.allocations.map((allocation) => allocation.amount), [
        Money.fromMinorUnits(933, Currency.eur),
        Money.fromMinorUnits(933, Currency.eur),
        Money.fromMinorUnits(934, Currency.eur),
      ]);
      expect(payload.total, Money.fromMinorUnits(2800, Currency.eur));
    });

    test('preserves a one-cent source with zero-valued early parts', () {
      final payload = ExpenseAllocationsPlannedPayload.evenly(
        expenseAmount: Money.fromMinorUnits(1, Currency.eur),
        cycleStarts: [
          LocalDate(2026, 3, 28),
          LocalDate(2026, 4, 4),
          LocalDate(2026, 4, 11),
        ],
      );

      expect(
        payload.allocations.map((allocation) => allocation.amount.minorUnits),
        [0, 0, 1],
      );
      expect(payload.total, Money.fromMinorUnits(1, Currency.eur));
    });

    test('rejects duplicate, unordered, empty, or overlong plans', () {
      ExpenseAllocation allocation(LocalDate date) {
        return ExpenseAllocation(
          cycleStart: date,
          amount: Money.fromMinorUnits(100, Currency.eur),
        );
      }

      expect(
        () => ExpenseAllocationsPlannedPayload(allocations: const []),
        throwsRangeError,
      );
      expect(
        () => ExpenseAllocationsPlannedPayload(
          allocations: [
            allocation(LocalDate(2026, 4, 4)),
            allocation(LocalDate(2026, 4, 4)),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ExpenseAllocationsPlannedPayload(
          allocations: [
            allocation(LocalDate(2026, 4, 4)),
            allocation(LocalDate(2026, 3, 28)),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => ExpenseAllocationsPlannedPayload.evenly(
          expenseAmount: Money.fromMinorUnits(1300, Currency.eur),
          cycleStarts: [
            for (var week = 0; week < 13; week++)
              LocalDate(2026, 3, 28).addDays(week * 7),
          ],
        ),
        throwsRangeError,
      );
    });
  });

  group('EventRecord', () {
    test('keeps business metadata outside its immutable payload', () {
      final event = _recordedEvent();

      expect(event.eventType, 'expense.recorded');
      expect(event.schemaVersion, 1);
      expect(event.businessDate, LocalDate(2026, 4, 1));
      expect(event.recordedAtUtc.isUtc, isTrue);
      expect(event.target.kind, EntityKind.expense);
    });

    test('requires a UTC recording instant', () {
      expect(
        () => EventRecord(
          id: EventId('018f1f3a-7b1c-7a2d-8e3f-1234567890ab'),
          recordedAtUtc: DateTime(2026, 4, 1, 12),
          businessDate: LocalDate(2026, 4, 1),
          target: _expenseReference(),
          payload: _recordedPayload(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('LocalJournalPosition', () {
    test('is positive, monotone-comparable, and signed-64-bit bounded', () {
      final first = LocalJournalPosition(1);
      final second = LocalJournalPosition(2);

      expect(first.compareTo(second), lessThan(0));
      expect(
        LocalJournalPosition(LocalJournalPosition.maxValue).value,
        LocalJournalPosition.maxValue,
      );
      expect(() => LocalJournalPosition(0), throwsRangeError);
    });
  });
}

EventRecord _recordedEvent() {
  return EventRecord(
    id: EventId('018f1f3a-7b1c-7a2d-8e3f-1234567890ab'),
    recordedAtUtc: DateTime.utc(2026, 4, 1, 10),
    businessDate: LocalDate(2026, 4, 1),
    target: _expenseReference(),
    payload: _recordedPayload(),
  );
}

ExpenseRecordedPayload _recordedPayload() {
  return ExpenseRecordedPayload(
    amount: Money.fromMinorUnits(4250, Currency.eur),
    label: 'Courses',
    cycleAssignment: _assignment(),
  );
}

ExpenseCycleAssignment _assignment() {
  return ExpenseCycleAssignment(
    cycleStart: LocalDate(2026, 3, 28),
    policyVersion: 1,
    timeZone: IanaTimeZoneId('Europe/Paris'),
  );
}

EntityReference _expenseReference() {
  return EntityReference(
    kind: EntityKind.expense,
    id: EntityId('01901111-1111-7111-8111-111111111111'),
  );
}
