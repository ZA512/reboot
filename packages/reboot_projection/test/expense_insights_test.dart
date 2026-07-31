import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:test/test.dart';

void main() {
  test('ranks normalized labels and reuses the latest nature', () {
    final ledger = ExpenseLedger.replay([
      ..._expense(
        index: 1,
        firstPosition: 1,
        label: 'Courses',
        amount: 1000,
        nature: ExpenseNature.necessary,
      ),
      ..._expense(
        index: 2,
        firstPosition: 4,
        label: '  courses  ',
        amount: 2000,
        nature: ExpenseNature.pleasure,
      ),
      ..._expense(index: 3, firstPosition: 7, label: 'Cinéma', amount: 3000),
    ]);

    final suggestions = ExpenseInsights.suggestions(ledger);

    expect(suggestions, hasLength(2));
    expect(suggestions.first.label.trim(), 'courses');
    expect(suggestions.first.useCount, 2);
    expect(suggestions.first.nature, ExpenseNature.pleasure);
    expect(suggestions.last.label, 'Cinéma');
  });

  test('breaks weekly allocations down without affecting their total', () {
    final ledger = ExpenseLedger.replay([
      ..._expense(
        index: 1,
        firstPosition: 1,
        label: 'Courses',
        amount: 1000,
        nature: ExpenseNature.necessary,
      ),
      ..._expense(
        index: 2,
        firstPosition: 4,
        label: 'Sortie',
        amount: 2000,
        nature: ExpenseNature.pleasure,
      ),
      ..._expense(index: 3, firstPosition: 7, label: 'Divers', amount: 3000),
    ]);

    final breakdown = ExpenseInsights.natureBreakdown(ledger, [_cycleStart]);

    expect(breakdown.total.minorUnits, 6000);
    expect(breakdown.amounts[ExpenseNature.necessary]!.minorUnits, 1000);
    expect(breakdown.amounts[ExpenseNature.pleasure]!.minorUnits, 2000);
    expect(breakdown.unqualified.minorUnits, 3000);
    expect(breakdown.shares.map((share) => share.basisPoints), [
      1666,
      3333,
      5000,
    ]);
  });

  test('validates suggestion limits', () {
    expect(
      () => ExpenseInsights.suggestions(ExpenseLedger.empty(), limit: -1),
      throwsRangeError,
    );
  });
}

List<LocalJournalEntry> _expense({
  required int index,
  required int firstPosition,
  required String label,
  required int amount,
  ExpenseNature? nature,
}) {
  final id = EntityId(
    '01901111-1111-7111-8111-${index.toString().padLeft(12, '0')}',
  );
  final target = EntityReference(kind: EntityKind.expense, id: id);
  final entries = <LocalJournalEntry>[
    _entry(
      firstPosition,
      target,
      ExpenseRecordedPayload(
        amount: _eur(amount),
        label: label,
        cycleAssignment: ExpenseCycleAssignment(
          cycleStart: _cycleStart,
          policyVersion: 1,
          timeZone: IanaTimeZoneId('Europe/Paris'),
        ),
      ),
    ),
    _entry(
      firstPosition + 1,
      target,
      ExpenseAllocationsPlannedPayload.evenly(
        expenseAmount: _eur(amount),
        cycleStarts: [_cycleStart],
      ),
    ),
  ];
  if (nature != null) {
    entries.add(
      _entry(
        firstPosition + 2,
        target,
        ExpenseNatureSetPayload(nature: nature),
      ),
    );
  }
  return entries;
}

LocalJournalEntry _entry(
  int position,
  EntityReference target,
  EventPayload payload,
) => LocalJournalEntry(
  position: LocalJournalPosition(position),
  event: EventRecord(
    id: EventId(
      '018f2b8a-7d3c-7a1b-8c4d-${position.toString().padLeft(12, '0')}',
    ),
    recordedAtUtc: DateTime.utc(2026, 4, 1, 10, 0, position),
    businessDate: LocalDate(2026, 4, 1),
    target: target,
    payload: payload,
  ),
);

final _cycleStart = LocalDate(2026, 3, 28);

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
