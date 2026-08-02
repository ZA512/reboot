import 'dart:convert';

import 'package:reboot_domain/reboot_domain.dart';
import 'package:reboot_projection/reboot_projection.dart';
import 'package:reboot_serialization/reboot_serialization.dart';
import 'package:test/test.dart';

void main() {
  group('ExpenseLedgerSnapshotCodec', () {
    final codec = ExpenseLedgerSnapshotCodec();

    test('round-trips complete state and resumes an exact suffix', () {
      final entries = _completeHistory();
      final checkpointLedger = ExpenseLedger.replay(entries.take(5));

      final encoded = codec.encode(checkpointLedger);
      final restored = codec.decode(encoded);
      final resumed = restored.apply(entries.last);
      final fullReplay = ExpenseLedger.replay(entries);

      expect(codec.encode(restored), encoded);
      expect(restored.expenses, checkpointLedger.expenses);
      expect(
        restored.expenses[_firstExpenseId].hashCode,
        checkpointLedger.expenses[_firstExpenseId].hashCode,
      );
      expect(restored.lastPosition, checkpointLedger.lastPosition);
      expect(codec.encode(resumed), codec.encode(fullReplay));
      expect(
        resumed.expenses[_firstExpenseId]!.nature,
        ExpenseNature.necessary,
      );
      expect(resumed.expenses[_firstExpenseId]!.refundedAmount, _eur(0));
    });

    test('is deterministic regardless of checkpoint entity order', () {
      final ledger = ExpenseLedger.replay([
        _recordedEntry(1, _firstExpenseId, amount: 15000, label: 'Courses'),
        _recordedEntry(2, _secondExpenseId, amount: 4200, label: 'Cinéma'),
      ]);
      final reversed = ExpenseLedger.fromCheckpoint(
        expenses: ledger.expenses.values.toList().reversed,
        lastPosition: ledger.lastPosition!,
      );

      expect(codec.encode(reversed), codec.encode(ledger));
    });

    test('preserves signed int64 money and position exactly', () {
      final expense = ProjectedExpense.fromCheckpoint(
        id: _firstExpenseId,
        amount: Money.fromMinorUnitsBigInt(Money.maxMinorUnits, Currency.eur),
        label: 'Exact',
        purchaseDate: LocalDate(2026, 8, 1),
        cycleAssignment: _assignment(),
        recordedAtUtc: DateTime.utc(2026, 8, 1),
        recordingEventId: _eventId(1),
        refunds: const [],
      );
      final ledger = ExpenseLedger.fromCheckpoint(
        expenses: [expense],
        lastPosition: LocalJournalPosition.fromBigInt(Money.maxMinorUnits),
      );

      final encoded = codec.encode(ledger);
      final restored = codec.decode(encoded);

      expect(encoded, contains('"minorUnits":"9223372036854775807"'));
      expect(encoded, contains('"lastPosition":"9223372036854775807"'));
      expect(
        restored.expenses[_firstExpenseId]!.amount.exactMinorUnits,
        Money.maxMinorUnits,
      );
      expect(restored.lastPosition!.exactValue, Money.maxMinorUnits);
    });

    test('rejects unsupported, malformed, and non-canonical snapshots', () {
      final source = codec.encode(
        ExpenseLedger.replay([
          _recordedEntry(1, _firstExpenseId, amount: 15000, label: 'Courses'),
        ]),
      );
      final root = jsonDecode(source) as Map<String, Object?>;

      expect(() => codec.decode(' $source'), throwsFormatException);
      expect(
        () => codec.decode(
          jsonEncode(<String, Object?>{...root, 'schemaVersion': 2}),
        ),
        throwsFormatException,
      );
      expect(
        () => codec.decode(
          jsonEncode(<String, Object?>{...root, 'unexpected': true}),
        ),
        throwsFormatException,
      );
      expect(
        () => codec.decode(
          jsonEncode(<String, Object?>{...root, 'lastPosition': '01'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects inconsistent projection invariants', () {
      final source = codec.encode(
        ExpenseLedger.replay([
          _recordedEntry(1, _firstExpenseId, amount: 15000, label: 'Courses'),
          _allocationEntry(2, _firstExpenseId, 15000),
        ]),
      );
      final root = jsonDecode(source) as Map<String, Object?>;
      final expenses = root['expenses']! as List<Object?>;
      final expense = expenses.single! as Map<String, Object?>;
      final allocations = expense['allocations']! as List<Object?>;
      final firstAllocation = allocations.first! as Map<String, Object?>;
      final amount = firstAllocation['amount']! as Map<String, Object?>;
      amount['minorUnits'] = '1';

      expect(() => codec.decode(jsonEncode(root)), throwsFormatException);
    });

    test('rejects snapshots above the bounded storage size', () {
      expect(
        () => codec.decode(
          'x' * (ExpenseLedgerSnapshotCodec.maximumEncodedBytes + 1),
        ),
        throwsFormatException,
      );
    });
  });
}

List<LocalJournalEntry> _completeHistory() => [
  _recordedEntry(1, _firstExpenseId, amount: 15000, label: 'Courses'),
  _allocationEntry(2, _firstExpenseId, 15000),
  _entry(
    3,
    _firstExpenseId,
    const ExpenseNatureSetPayload(nature: ExpenseNature.necessary),
  ),
  _entry(
    4,
    _firstExpenseId,
    ExpenseRefundedPayload(
      amount: _eur(3000),
      receiptCycleStart: LocalDate(2026, 8, 8),
    ),
  ),
  _entry(
    5,
    _firstExpenseId,
    ExpenseRefundReversedPayload(refundEventId: _eventId(4)),
  ),
  _recordedEntry(6, _secondExpenseId, amount: 4200, label: 'Cinéma'),
];

LocalJournalEntry _recordedEntry(
  int position,
  EntityId expenseId, {
  required int amount,
  required String label,
}) => _entry(
  position,
  expenseId,
  ExpenseRecordedPayload(
    amount: _eur(amount),
    label: label,
    cycleAssignment: _assignment(),
  ),
);

LocalJournalEntry _allocationEntry(
  int position,
  EntityId expenseId,
  int amount,
) => _entry(
  position,
  expenseId,
  ExpenseAllocationsPlannedPayload.evenly(
    expenseAmount: _eur(amount),
    cycleStarts: [
      LocalDate(2026, 8, 1),
      LocalDate(2026, 8, 8),
      LocalDate(2026, 8, 15),
    ],
  ),
);

LocalJournalEntry _entry(
  int position,
  EntityId expenseId,
  EventPayload payload,
) => LocalJournalEntry(
  position: LocalJournalPosition(position),
  event: EventRecord(
    id: _eventId(position),
    recordedAtUtc: DateTime.utc(2026, 8, 1, 10, 0, position),
    businessDate: LocalDate(2026, 8, 1),
    target: EntityReference(kind: EntityKind.expense, id: expenseId),
    payload: payload,
  ),
);

ExpenseCycleAssignment _assignment() => ExpenseCycleAssignment(
  cycleStart: LocalDate(2026, 8, 1),
  policyVersion: 1,
  timeZone: IanaTimeZoneId('Europe/Paris'),
);

final _firstExpenseId = EntityId('018f2b8a-7d3c-7a1b-8c4d-000000000001');
final _secondExpenseId = EntityId('018f2b8a-7d3c-7a1b-8c4d-000000000002');

EventId _eventId(int value) =>
    EventId('018f1f3a-7b1c-7a2d-8e3f-${value.toString().padLeft(12, '0')}');

Money _eur(int minorUnits) => Money.fromMinorUnits(minorUnits, Currency.eur);
