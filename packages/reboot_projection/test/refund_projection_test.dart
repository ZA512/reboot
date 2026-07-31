import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  group('expense refunds', () {
    test(
      'same-cycle refund restores remaining without changing installments',
      () {
        final cycles = _cycles();
        final ledger = ExpenseLedger.replay([
          ..._baseExpense(cycles),
          _entry(
            3,
            ExpenseRefundedPayload(
              amount: _eur(6000),
              receiptCycleStart: cycles.first.start,
            ),
            businessDate: cycles.first.start.addDays(2),
          ),
        ]);
        final projection = Rolling52Projection.build(
          cycles: cycles,
          budgetsByCycleStart: {
            for (final cycle in cycles) cycle.start: _eur(20000),
          },
          expenseLedger: ledger,
        );

        expect(projection.cycles.first.allocatedExpenses.minorUnits, 5000);
        expect(projection.cycles.first.refundCredits.minorUnits, 6000);
        expect(projection.cycles.first.remaining.minorUnits, 21000);
        expect(projection.cycles[1].remaining.minorUnits, 15000);
        expect(ledger.activeExpenses.single.refundableAmount.minorUnits, 9000);
      },
    );

    test(
      'later refund improves trajectory but not its receipt-week budget',
      () {
        final cycles = _cycles();
        final ledger = ExpenseLedger.replay([
          ..._baseExpense(cycles),
          _entry(
            3,
            ExpenseRefundedPayload(
              amount: _eur(6000),
              receiptCycleStart: cycles[3].start,
            ),
            businessDate: cycles[3].start,
          ),
        ]);
        final rolling = Rolling52Projection.build(
          cycles: cycles,
          budgetsByCycleStart: {
            for (final cycle in cycles) cycle.start: _eur(20000),
          },
          expenseLedger: ledger,
        );
        final trends = TrendProjection.build([
          TrendCycleObservation(
            cycle: cycles[3],
            budget: _eur(20000),
            allocatedExpenses: _eur(23000),
            trajectoryCredits: _eur(6000),
          ),
        ]);

        expect(rolling.cycles[3].remaining.minorUnits, 20000);
        expect(trends.balance.minorUnits, 3000);
        expect(trends.latestOverspend.minorUnits, 3000);
        expect(
          trends.latestOverspendRatio!.severity,
          TrendAlertSeverity.strong,
        );
      },
    );

    test('rejects over-refunding and reverses a mistaken refund', () {
      final cycles = _cycles();
      final refundId = _eventId(3);
      expect(
        () => ExpenseLedger.replay([
          ..._baseExpense(cycles),
          _entry(
            3,
            ExpenseRefundedPayload(
              amount: _eur(15001),
              receiptCycleStart: cycles.first.start,
            ),
          ),
        ]),
        throwsA(isA<ProjectionConflictException>()),
      );

      final ledger = ExpenseLedger.replay([
        ..._baseExpense(cycles),
        _entry(
          3,
          ExpenseRefundedPayload(
            amount: _eur(6000),
            receiptCycleStart: cycles.first.start,
          ),
        ),
        _entry(4, ExpenseRefundReversedPayload(refundEventId: refundId)),
      ]);
      expect(ledger.activeExpenses.single.refundedAmount, _eur(0));
      expect(ledger.activeExpenses.single.refunds.single.isReversed, isTrue);
    });
  });
}

List<WeeklyCycle> _cycles() {
  final policy = CyclePolicy(
    version: 1,
    effectiveFrom: LocalDate(2026, 1, 3),
    anchorWeekday: Weekday.saturday,
    timeZone: IanaTimeZoneId('Europe/Paris'),
  );
  return CycleCalendar.normalCycles(
    policy: policy,
    firstStart: policy.effectiveFrom,
    count: 52,
  );
}

List<LocalJournalEntry> _baseExpense(List<WeeklyCycle> cycles) => [
  _entry(
    1,
    ExpenseRecordedPayload(
      amount: _eur(15000),
      label: 'Achat',
      cycleAssignment: ExpenseCycleAssignment(
        cycleStart: cycles.first.start,
        policyVersion: 1,
        timeZone: IanaTimeZoneId('Europe/Paris'),
      ),
    ),
  ),
  _entry(
    2,
    ExpenseAllocationsPlannedPayload.evenly(
      expenseAmount: _eur(15000),
      cycleStarts: [for (final cycle in cycles.take(3)) cycle.start],
    ),
  ),
];

LocalJournalEntry _entry(
  int position,
  EventPayload payload, {
  LocalDate? businessDate,
}) => LocalJournalEntry(
  position: LocalJournalPosition(position),
  event: EventRecord(
    id: _eventId(position),
    recordedAtUtc: DateTime.utc(2026, 1, 3, 10, 0, position),
    businessDate: businessDate ?? LocalDate(2026, 1, 3),
    target: EntityReference(kind: EntityKind.expense, id: _expenseId),
    payload: payload,
  ),
);

final _expenseId = EntityId('018f2b8a-7d3c-7a1b-8c4d-1234567890ab');

EventId _eventId(int value) =>
    EventId('018f2b8a-7d3c-7a1b-8c4d-${value.toString().padLeft(12, '0')}');

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
