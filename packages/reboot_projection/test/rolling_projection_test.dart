import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('Rolling52Projection', () {
    test('adds overlapping three-cycle expense plans', () {
      final cycles = _normalHorizon();
      final ledger = ExpenseLedger.replay([
        ..._expenseEntries(
          identity: 1,
          firstPosition: 1,
          amountMinorUnits: 15000,
          cycleStarts: [
            for (var index = 0; index < 3; index++) cycles[index].start,
          ],
        ),
        ..._expenseEntries(
          identity: 2,
          firstPosition: 3,
          amountMinorUnits: 15000,
          cycleStarts: [
            for (var index = 1; index < 4; index++) cycles[index].start,
          ],
        ),
      ]);
      final projection = Rolling52Projection.build(
        cycles: cycles,
        budgetsByCycleStart: _constantBudgets(cycles, 20000),
        expenseLedger: ledger,
      );

      expect(
        projection.cycles
            .take(4)
            .map((cycle) => cycle.allocatedExpenses.minorUnits),
        [5000, 10000, 10000, 5000],
      );
      expect(
        projection.cycles.take(4).map((cycle) => cycle.remaining.minorUnits),
        [15000, 10000, 10000, 15000],
      );
    });

    test('does not carry a surplus or deficit into the next cycle', () {
      final cycles = _normalHorizon();
      final ledger = ExpenseLedger.replay(
        _expenseEntries(
          identity: 1,
          firstPosition: 1,
          amountMinorUnits: 30000,
          cycleStarts: [cycles.first.start],
        ),
      );
      final projection = Rolling52Projection.build(
        cycles: cycles,
        budgetsByCycleStart: _constantBudgets(cycles, 20000),
        expenseLedger: ledger,
      );

      expect(projection.cycles.first.remaining.minorUnits, -10000);
      expect(projection.cycles.first.isOverBudget, isTrue);
      expect(projection.cycles[1].budget.minorUnits, 20000);
      expect(projection.cycles[1].remaining.minorUnits, 20000);
    });

    test('removes all allocations when the real expense is tombstoned', () {
      final cycles = _normalHorizon();
      final entries = _expenseEntries(
        identity: 1,
        firstPosition: 1,
        amountMinorUnits: 15000,
        cycleStarts: [
          for (var index = 0; index < 3; index++) cycles[index].start,
        ],
      );
      final ledger = ExpenseLedger.replay([
        ...entries,
        LocalJournalEntry(
          position: LocalJournalPosition(3),
          event: EventRecord(
            id: _eventId(99),
            recordedAtUtc: DateTime.utc(2026, 1, 4),
            businessDate: LocalDate(2026, 1, 4),
            target: EntityReference(kind: EntityKind.expense, id: _entityId(1)),
            payload: const ExpenseDeletedPayload(),
          ),
        ),
      ]);
      final projection = Rolling52Projection.build(
        cycles: cycles,
        budgetsByCycleStart: _constantBudgets(cycles, 20000),
        expenseLedger: ledger,
      );

      expect(
        projection.cycles
            .take(3)
            .map((cycle) => cycle.allocatedExpenses.minorUnits),
        [0, 0, 0],
      );
    });

    test('keeps the full weekly budget on an exceptional transition', () {
      final previousPolicy = _policy(
        version: 1,
        effectiveFrom: LocalDate(2026, 3, 21),
        anchor: Weekday.saturday,
      );
      final change = CycleCalendar.changeAnchor(
        previousPolicy: previousPolicy,
        nextPolicy: _policy(
          version: 2,
          effectiveFrom: LocalDate(2026, 4, 1),
          anchor: Weekday.monday,
        ),
      );
      final cycles = <WeeklyCycle>[
        WeeklyCycle.normal(
          start: LocalDate(2026, 3, 21),
          policy: previousPolicy,
        ),
        change.transition,
        ...CycleCalendar.normalCycles(
          firstStart: change.firstNormalCycle.start,
          count: 50,
          policy: change.firstNormalCycle.policy,
        ),
      ];
      final projection = Rolling52Projection.build(
        cycles: cycles,
        budgetsByCycleStart: _constantBudgets(cycles, 23000),
        expenseLedger: ExpenseLedger.empty(),
      );

      expect(projection.cycles, hasLength(52));
      expect(projection.cycles[1].cycle.kind, WeeklyCycleKind.transition);
      expect(projection.cycles[1].cycle.dateCount, 9);
      expect(projection.cycles[1].budget.minorUnits, 23000);
      expect(projection.cycles[1].remaining.minorUnits, 23000);
    });

    test('requires 52 gap-free cycles and one budget for each', () {
      final cycles = _normalHorizon();

      expect(
        () => Rolling52Projection.build(
          cycles: cycles.take(51).toList(),
          budgetsByCycleStart: _constantBudgets(cycles, 20000),
          expenseLedger: ExpenseLedger.empty(),
        ),
        throwsArgumentError,
      );

      final missingBudget = _constantBudgets(cycles, 20000)
        ..remove(cycles.last.start);
      expect(
        () => Rolling52Projection.build(
          cycles: cycles,
          budgetsByCycleStart: missingBudget,
          expenseLedger: ExpenseLedger.empty(),
        ),
        throwsA(isA<MissingCycleBudgetException>()),
      );
    });

    test('refuses an active expense without its allocation event', () {
      final cycles = _normalHorizon();
      final recordedOnly = ExpenseLedger.replay([
        _expenseEntries(
          identity: 1,
          firstPosition: 1,
          amountMinorUnits: 1000,
          cycleStarts: [cycles.first.start],
        ).first,
      ]);

      expect(
        () => Rolling52Projection.build(
          cycles: cycles,
          budgetsByCycleStart: _constantBudgets(cycles, 20000),
          expenseLedger: recordedOnly,
        ),
        throwsA(isA<UnallocatedExpenseException>()),
      );
    });

    test('refuses an in-horizon date that is not a cycle start', () {
      final cycles = _normalHorizon();
      final ledger = ExpenseLedger.replay(
        _expenseEntries(
          identity: 1,
          firstPosition: 1,
          amountMinorUnits: 1000,
          cycleStarts: [cycles.first.start.addDays(1)],
        ),
      );

      expect(
        () => Rolling52Projection.build(
          cycles: cycles,
          budgetsByCycleStart: _constantBudgets(cycles, 20000),
          expenseLedger: ledger,
        ),
        throwsA(isA<InvalidAllocationCycleException>()),
      );
    });
  });
}

List<WeeklyCycle> _normalHorizon() {
  final policy = _policy(
    version: 1,
    effectiveFrom: LocalDate(2026, 1, 3),
    anchor: Weekday.saturday,
  );
  return CycleCalendar.normalCycles(
    firstStart: LocalDate(2026, 1, 3),
    count: 52,
    policy: policy,
  );
}

CyclePolicy _policy({
  required int version,
  required LocalDate effectiveFrom,
  required Weekday anchor,
}) {
  return CyclePolicy(
    version: version,
    effectiveFrom: effectiveFrom,
    anchorWeekday: anchor,
    timeZone: IanaTimeZoneId('Europe/Paris'),
  );
}

Map<LocalDate, Money> _constantBudgets(
  Iterable<WeeklyCycle> cycles,
  int minorUnits,
) {
  return {
    for (final cycle in cycles)
      cycle.start: Money.fromMinorUnits(minorUnits, Currency.eur),
  };
}

List<LocalJournalEntry> _expenseEntries({
  required int identity,
  required int firstPosition,
  required int amountMinorUnits,
  required List<LocalDate> cycleStarts,
}) {
  final entity = EntityReference(
    kind: EntityKind.expense,
    id: _entityId(identity),
  );
  final amount = Money.fromMinorUnits(amountMinorUnits, Currency.eur);
  return [
    LocalJournalEntry(
      position: LocalJournalPosition(firstPosition),
      event: EventRecord(
        id: _eventId(identity * 10),
        recordedAtUtc: DateTime.utc(2026, 1, 3, 10),
        businessDate: cycleStarts.first,
        target: entity,
        payload: ExpenseRecordedPayload(
          amount: amount,
          label: 'Expense $identity',
          cycleAssignment: ExpenseCycleAssignment(
            cycleStart: cycleStarts.first,
            policyVersion: 1,
            timeZone: IanaTimeZoneId('Europe/Paris'),
          ),
        ),
      ),
    ),
    LocalJournalEntry(
      position: LocalJournalPosition(firstPosition + 1),
      event: EventRecord(
        id: _eventId((identity * 10) + 1),
        recordedAtUtc: DateTime.utc(2026, 1, 3, 10, 0, 1),
        businessDate: cycleStarts.first,
        target: entity,
        payload: ExpenseAllocationsPlannedPayload.evenly(
          expenseAmount: amount,
          cycleStarts: cycleStarts,
        ),
      ),
    ),
  ];
}

EntityId _entityId(int value) => EntityId(_uuid(value));

EventId _eventId(int value) => EventId(_uuid(value + 1000));

String _uuid(int value) {
  final suffix = value.toRadixString(16).padLeft(12, '0');
  return '01900000-0000-7000-8000-$suffix';
}
